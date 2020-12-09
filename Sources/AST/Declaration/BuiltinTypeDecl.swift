import Basic

/// A built-in type declaration.
public final class BuiltinTypeDecl: NominalTypeDecl {

  /// Creates a new built-in type declaration.
  ///
  /// - Parameter name: The name of the built-in type.
  init(type: BuiltinType) {
    self.type = type
    type.decl = self
  }

  public var name: String { (type as! BuiltinType).name }

  public let type: BareType?

  public weak var declContext: DeclContext?

  public let range: SourceRange? = SourceLocation.unknown ..< SourceLocation.unknown

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}
