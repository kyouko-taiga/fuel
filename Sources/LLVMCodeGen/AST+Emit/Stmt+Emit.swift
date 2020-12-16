import LLVM
import AST

extension Stmt {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    guard let emittable = self as? ValueEmittable else {
      fatalError("value is not emittable")
    }
    return emittable.emit(in: &cgContext)
  }

}

extension CallStmt: ValueEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    // Retrieve the declaration of the function being called.
    guard let funcDecl = ident.referredDecl as? FuncDecl else {
      fatalError("'\(ident.name)' does not refer to a function declaration")
    }

    // Handle built-in functions.
    if funcDecl.isBuiltin {
      return emitBuiltinCall(to: funcDecl, in: &cgContext)
    }

    let llvmFunc = cgContext.function(decl: funcDecl)

    // Prepare the function arguments.
    var llvmArgs: [IRValue] = []
    let funcTy = funcDecl.bareFuncType!

    for (fuelArg, paramTy) in zip(args, funcTy.params) {
      switch paramTy.bareType.passingPolicy {
      case .skipped:
        continue

      case .direct:
        llvmArgs.append(fuelArg.emit(in: &cgContext))

      case .indirect:
        let alloca = cgContext.builder.buildAllocaInEntry(
          of: cgContext.builder.currentFunction!,
          type: paramTy.emit(in: &cgContext))

        // FIXME: Avoid load/store on large structs.
        cgContext.builder.buildStore(fuelArg.emit(in: &cgContext), to: alloca)
        llvmArgs.append(alloca)
      }
    }

    // Emit the function all.
    let inst: IRInstruction

    if funcTy.output.bareType.passingPolicy == .indirect {
      // Allocate storage for the return value.
      let llvmReturnTy = funcTy.output.emit(in: &cgContext)
      let alloca = cgContext.builder.buildAllocaInEntry(
        of: cgContext.builder.currentFunction!,
        type: llvmReturnTy)
      llvmArgs.insert(alloca, at: 0)
      _ = cgContext.builder.buildCall(llvmFunc, args: llvmArgs)

      // The result of the instruction is a load on the pre-allocated return value.
      // FIXME: Avoid load/store on large structs.
      inst = cgContext.builder.buildLoad(alloca, type: llvmReturnTy, name: name)
    } else {
      inst = cgContext.builder.buildCall(llvmFunc, args: llvmArgs, name: name)
    }

    cgContext.environment[symbol] = inst
    return inst
  }

  func emitBuiltinCall(to funcDecl: FuncDecl, in cgContext: inout CodeGenContext) -> IRValue {
    let builder = cgContext.builder
    let llvmArgs = args.map({ $0.emit(in: &cgContext) })
    let inst: IRValue

    let components = funcDecl.name.split(separator: "_", maxSplits: 1)
    switch components.first {
    case "add":
      inst = builder.buildAdd(llvmArgs[0], llvmArgs[1])
    case "sub":
      inst = builder.buildSub(llvmArgs[0], llvmArgs[1])
    case "mul":
      inst = builder.buildMul(llvmArgs[0], llvmArgs[1])
    case "div":
      inst = builder.buildDiv(llvmArgs[0], llvmArgs[1])
    case "eq" where components[1].starts(with: "Int"):
      inst = builder.buildICmp(llvmArgs[0], llvmArgs[1], .equal)
    case "ne" where components[1].starts(with: "Int"):
      inst = builder.buildICmp(llvmArgs[0], llvmArgs[1], .notEqual)
    case "ge" where components[1].starts(with: "Int"):
      inst = builder.buildICmp(llvmArgs[0], llvmArgs[1], .signedGreaterThanOrEqual)
    case "gt" where components[1].starts(with: "Int"):
      inst = builder.buildICmp(llvmArgs[0], llvmArgs[1], .signedGreaterThan)
    case "le" where components[1].starts(with: "Int"):
      inst = builder.buildICmp(llvmArgs[0], llvmArgs[1], .signedLessThanOrEqual)
    case "lt" where components[1].starts(with: "Int"):
      inst = builder.buildICmp(llvmArgs[0], llvmArgs[1], .signedLessThan)

    default:
      fatalError("unreachable")
    }

    cgContext.environment[symbol] = inst
    return inst
  }

}

extension IfStmt: ValueEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    // Create basic blocks for each branch.
    let llvmFunc = cgContext.builder.currentFunction!
    let thenBB = llvmFunc.appendBasicBlock(named: "then", in: cgContext.llvmContext)
    let elseBB = llvmFunc.appendBasicBlock(named: "else", in: cgContext.llvmContext)
    let joinBB = llvmFunc.appendBasicBlock(named: "join", in: cgContext.llvmContext)

    // Emit a branch statement.
    let condVal = cond.emit(in: &cgContext)
    let inst = cgContext.builder.buildCondBr(condition: condVal, then: thenBB, else: elseBB)

    // Emit the contents of each branch.
    cgContext.builder.positionAtEnd(of: thenBB)
    for stmt in thenBody.stmts {
      _ = stmt.emit(in: &cgContext)
    }
    cgContext.builder.buildBr(joinBB)

    cgContext.builder.positionAtEnd(of: elseBB)
    for stmt in elseBody?.stmts ?? [] {
      _ = stmt.emit(in: &cgContext)
    }
    cgContext.builder.buildBr(joinBB)

    // Position the builder in the join block.
    cgContext.builder.positionAtEnd(of: joinBB)
    return inst
  }

}

extension LoadStmt: ValueEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    let ptr = lvalue.emit(in: &cgContext)
    let type = (ptr.type as! PointerType).pointee
    let inst = cgContext.builder.buildLoad(ptr, type: type, name: name)
    cgContext.environment[symbol] = inst
    return inst
  }

}

extension ReturnStmt: ValueEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    let funcDecl = cgContext.currentFuncDecl!

    switch funcDecl.bareFuncType!.output.bareType.passingPolicy {
    case .direct:
      let val = value.emit(in: &cgContext)
      return cgContext.builder.buildRet(val)

    case .indirect:
      let val = value.emit(in: &cgContext)
      let ptr = cgContext.builder.currentFunction!.parameters[0]

      // FIXME: Avoid load/store on large structs.
      cgContext.builder.buildStore(val, to: ptr)
      return cgContext.builder.buildRetVoid()

    case .skipped:
      return cgContext.builder.buildRetVoid()
    }
  }

}

extension AllocStmt: ValueEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    precondition(cgContext.environment[symbol] == nil)

    let inst = cgContext.builder.buildAllocaInEntry(
      of: cgContext.builder.currentFunction!,
      type: sign.type!.emit(in: &cgContext),
      name: name)
    cgContext.environment[symbol] = inst
    return inst
  }

}

extension StoreStmt: ValueEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    let ptr = lvalue.emit(in: &cgContext)
    let val = rvalue.emit(in: &cgContext)
    return cgContext.builder.buildStore(val, to: ptr)
  }

}
