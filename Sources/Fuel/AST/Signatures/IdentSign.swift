/// A type identifier.
public final class IdentSign: TypeSign {

  /// Creates a new type identifier.
  ///
  /// - Parameter name: The name of the referred type.
  public init(name: String) {
    self.name = name
  }

  /// The name of the referred type.
  public var name: String

  /// The declaration to which this identifier refers.
  public var referredDecl: NominalTypeDecl?

  public var type: TypeBase?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension IdentSign: CustomStringConvertible {

  public var description: String {
    return name
  }

}
