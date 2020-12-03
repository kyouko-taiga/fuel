import Basic

public final class AssumptionSign {

  public init(ident: IdentExpr, sign: TypeSign) {
    self.ident = ident
    self.sign = sign
  }

  /// The identifier for which the assumption is made.
  public var ident: IdentExpr

  public var sign: TypeSign

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension AssumptionSign: CustomStringConvertible {

  public var description: String {
    return "[\(ident): \(sign)]"
  }

}
