import Basic

/// A quantified type signature.
public final class QuantifiedSign: TypeSign, DeclContext {

  public init(quantifier: Quantifier, params: [QuantifiedParamDecl], base: TypeSign) {
    self.quantifier = quantifier
    self.base = base
    self.params = params
  }

  public var quantifier: Quantifier

  public var params: [QuantifiedParamDecl]

  public var base: TypeSign

  public var type: QualType?

  public var parent: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

  public func decls(named name: String) -> AnySequence<NamedDecl> {
    return AnySequence(params.filter({ $0.name == name }))
  }

  public func firstDecl(named name: String) -> NamedDecl? {
    return params.first(where: { $0.name == name })
  }

}

extension QuantifiedSign: CustomStringConvertible {

  public var description: String {
    let tail = params.map(String.init(describing:)).joined(separator: ", ")

    let q: String
    switch quantifier {
    case .universal:
      q = "\\A"
    case .existential:
      q = "\\E"
    }

    switch base {
    case is FuncSign, is QuantifiedSign:
      return "\(q) \(tail) . (\(base))"
    default:
      return "\(q) \(tail) . \(base)"
    }
  }

}
