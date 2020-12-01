/// A built-in type declaration.
public final class BuiltinTypeDecl: NominalTypeDecl {

  /// Creates a new built-in type declaration.
  ///
  /// - Parameter type: The semantic type represented by the declaration.
  init(type: BuiltinType) {
    self.type = type
    name = type.name
    range = SourceLocation.unknown ..< SourceLocation.unknown
  }

  public let name: String

  public let type: BareType?

  public weak var declContext: DeclContext?

  public let range: SourceRange?

  public func accept<V>(_ visitor: V) where V : Visitor {
    visitor.visit(self)
  }

}
