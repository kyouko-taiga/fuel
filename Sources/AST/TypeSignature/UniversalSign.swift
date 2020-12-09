import Basic

/// A universally quantified type signature.
public final class UniversalSign: TypeSign, DeclContext {

  public init(base: TypeSign, params: [QuantifiedParamDecl]) {
    self.base = base
    self.params = params
  }

  public var base: TypeSign

  public var type: QualType?

  public var params: [QuantifiedParamDecl]

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

extension UniversalSign: CustomStringConvertible {

  public var description: String {
    let tail = params.map(String.init(describing:)).joined(separator: ", ")

    switch base {
    case is FuncSign, is UniversalSign:
      return "\\A \(tail) . (\(base))"
    default:
      return "\\A \(tail) . \(base)"
    }
  }

}
