import Basic

/// A named declaration.
public protocol NamedDecl: ASTNode, AnyObject {

  /// The name of the declared entity.
  var name: String { get }

  /// The symbol uniquely identifying this declaration.
  var symbol: Symbol { get }

  /// Returns whether the declaration is built-in.
  var isBuiltin: Bool { get }

  /// The context in which the entity is being declared.
  var declContext: DeclContext? { get }

}

extension NamedDecl {

  @inlinable public var symbol: Symbol { Symbol(decl: self) }

  @inlinable public var isBuiltin: Bool { declContext is BuiltinModule }

}
