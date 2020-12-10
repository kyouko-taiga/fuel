import Basic

/// A built-in type declaration.
public final class BuiltinTypeDecl: NominalTypeDecl {

  /// Creates a new built-in type declaration.
  ///
  /// - Parameter name: The name of the built-in type.
  init(type: BuiltinType) {
    self.type = type
  }

  public let type: BareType?

  public var name: String { (type as! BuiltinType).name }

  public var declContext: DeclContext? {
    return (type as! BuiltinType).context.builtin
  }

  public var range: SourceRange? { nil }

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}
