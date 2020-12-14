import Basic

/// A named declaration.
public protocol NamedDecl: AnyObject {

  /// The name of the declared entity.
  var name: String { get }

  /// The symbol uniquely identifying this declaration.
  var symbol: Symbol { get }

  /// Returns whether the declaration is built-in.
  var isBuiltin: Bool { get }

  /// The context in which the entity is being declared.
  var declContext: DeclContext? { get }

  /// The range of the declaration in the source.
  var range: SourceRange? { get }

  /// Accepts an AST visitor.
  func accept<V>(_ visitor: V) where V: Visitor

}

extension NamedDecl {

  @inlinable public var symbol: Symbol { Symbol(decl: self) }

  @inlinable public var isBuiltin: Bool { declContext is BuiltinModule }

}
