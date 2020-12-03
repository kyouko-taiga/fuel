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

  public var decls: [NamedDecl] { params as [NamedDecl] }

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
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
