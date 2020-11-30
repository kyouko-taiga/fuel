public protocol TypeSign {

  /// The semantic type represented by the signature.
  var type: TypeBase? { get }

  /// The signature's range in the source.
  var range: SourceRange? { get set }

  /// Accepts an AST visitor.
  func accept<V>(_ visitor: V) where V: Visitor

}
