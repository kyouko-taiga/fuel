import LLVM
import AST

/// LLVM IR code generator.
public struct CodeGenerator {

  public init(module: AST.Module) {
    self.module = module
    self.context = CodeGenContext(moduleName: module.id)
  }

  /// The Fuel module to transpile.
  public let module: AST.Module

  /// The generator's context.
  public var context: CodeGenContext

  // MARK: LLVM emitters

  public mutating func emit() -> LLVM.Module {
    for decl in module.funcDecls.values where !decl.isBuiltin {
      _ = decl.emit(in: &context)
    }
    return context.llvmModule
  }

}
