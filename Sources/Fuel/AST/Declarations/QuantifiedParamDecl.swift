/// A parameter of a quantified type signature.
public final class QuantifiedParamDecl: NamedDecl {

  public init(name: String) {
    self.name = name
  }

  public var name: String

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension QuantifiedParamDecl: CustomStringConvertible {

  public var description: String {
    return name
  }

}
