import Foundation

public enum CompilerAction {

  /// Parses the specified URL, resulting on the production of a raw AST.
  ///
  /// This action assigns the driver's `module` property.
  case parse(URL)

  /// Runs all phases of the semantic analysis.
  case runSema

}
