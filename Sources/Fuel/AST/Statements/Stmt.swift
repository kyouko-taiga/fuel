public protocol Stmt {

  /// The statement's range in the source.
  var range: SourceRange? { get }

  /// Accepts an AST visitor.
  func accept<V>(_ visitor: V) where V: Visitor

}
