import Basic

/// A named declaration.
public protocol NamedDecl: AnyObject {

  /// The name of the declared entity.
  var name: String { get }

  /// The context in which the entity is being declared.
  var declContext: DeclContext? { get set }

  /// The range of the declaration in the source.
  var range: SourceRange? { get }

  /// Accepts an AST visitor.
  func accept<V>(_ visitor: V) where V: Visitor

}
