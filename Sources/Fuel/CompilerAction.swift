import Foundation

public enum CompilerAction {

  /// Parses the specified URL, resulting on the production of a raw AST.
  ///
  /// This action updates the top-level declarations.
  case parse(URL)

  /// Runs all phases of the semantic analysis on all top-level declarations.
  case runSema

  /// Transpiles the module into LLVM IR.
  case emitLLVM

}
