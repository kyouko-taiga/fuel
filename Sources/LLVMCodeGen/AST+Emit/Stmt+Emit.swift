import LLVM
import AST

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
    let llvmArgs = args.map({ $0.emit(in: &cgContext) })
    let inst: IRValue

    let components = funcDecl.name.split(separator: "_", maxSplits: 1)
    switch components.first {
    case "add":
      precondition(llvmArgs.count == 2)
      inst = cgContext.builder.buildAdd(llvmArgs[0], llvmArgs[1])

    default:
      fatalError("unreachable")
    }

    cgContext.environment[symbol] = inst
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

extension ScopeAllocStmt: ValueEmittable {

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
