import LLVM
import AST

public struct CodeGenContext {

  /// Create a new code generator context.
  ///
  /// - Parameter moduleName: The name of the LLVM module to generate.
  public init(moduleName: String) {
    llvmModule = LLVM.Module(name: moduleName)
    llvmModule.targetTriple = Triple.default

    builder = IRBuilder(module: llvmModule)
  }

  /// The LLVM module being generated.
  public let llvmModule: LLVM.Module

  /// The builder that's used to create IR instructions.
  public let builder: IRBuilder

  /// The LLVM context owning the module.
  public var llvmContext: LLVM.Context { llvmModule.context }

  public var llvmVoid : VoidType    { VoidType(in: llvmContext) }
  public var llvmAny  : PointerType { PointerType(pointee: llvmVoid) }
  public var llvmBool : IntType     { IntType(width: 1, in: llvmContext) }
  public var llvmInt32: IntType     { IntType(width: 32, in: llvmContext) }
  public var llvmInt64: IntType     { IntType(width: 64, in: llvmContext) }

  /// A table mapping AST symbols to IR values.
  var environment: [AST.Symbol: IRValue] = [:]

  /// The function being emitted.
  var currentFuncDecl: FuncDecl?

  mutating func function(decl: FuncDecl) -> Function {
    // Check if the function has already been created.
    if let llvmFunc = llvmModule.function(named: decl.name) {
      return llvmFunc
    }

    // Retrive the fuel type of the function.
    let funcTy = decl.bareFuncType!

    // Build the LLVM parameters.
    var llvmParamTys: [IRType] = []
    var llvmParamAttrs: [[AttributeKind]] = []

    for paramTy in funcTy.params {
      let irType = paramTy.emit(in: &self)

      switch paramTy.bareType.passingPolicy {
      case .skipped:
        continue

      case .direct:
        llvmParamTys.append(irType)
        llvmParamAttrs.append([])

      case .indirect:
        llvmParamTys.append(PointerType(pointee: irType))
        llvmParamAttrs.append([.byval])
      }
    }

    // Build the LLVM return type.
    var llvmReturnTy = funcTy.output.emit(in: &self)

    switch funcTy.output.bareType.passingPolicy {
    case .skipped:
      llvmReturnTy = llvmVoid

    case .indirect:
      llvmParamTys.insert(PointerType(pointee: llvmReturnTy), at: 0)
      llvmParamAttrs.insert([.sret, .noalias], at: 0)
      llvmReturnTy = llvmVoid

    case .direct:
      break
    }

    // Create the function.
    let llvmFuncTy = FunctionType(llvmParamTys, llvmReturnTy)
    let llvmFunc = builder.addFunction(decl.name, type: llvmFuncTy)

    for i in 0 ..< llvmParamAttrs.count {
      for kind in llvmParamAttrs[i] {
        llvmFunc.addAttribute(kind, to: .argument(i))
      }
    }

    return llvmFunc
  }

}
