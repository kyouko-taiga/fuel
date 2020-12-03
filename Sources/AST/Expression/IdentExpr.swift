import Basic

/// A reference to a value declaration.
public final class IdentExpr: Expr {

  /// Creates a new reference to a value declaration.
  ///
  /// - Parameter name: The name of the referred declaration.
  public init(name: String) {
    self.name = name
  }

  /// The name of the referred declaration.
  public var name: String

  /// The referred declaration.
  public var referredDecl: NamedDecl?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension IdentExpr: CustomStringConvertible {

  public var description: String {
    return name
  }

}
