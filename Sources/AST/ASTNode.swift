import Basic

public protocol ASTNode {

  /// The node's range in the source.
  var range: SourceRange? { get }

  /// Accepts an AST visitor.
  func accept<V>(_ visitor: V) where V: Visitor

}
