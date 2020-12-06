import AST
import Lexer

extension TypeQual {

  /// Creates a type qualifier from the given token.
  ///
  /// - Parameter token: A token identifying a qualifier.
  init?(token: Token) {
    switch token.value {
    case "@const"   : self = .const
    case "@unscoped": self = .unscoped
    default         : return nil
    }
  }

}
