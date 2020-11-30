public final class PointerSign: TypeSign {

  public init(base: TypeSign) {
    self.base = base
  }

  public var base: TypeSign

  public var type: TypeBase?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension PointerSign: CustomStringConvertible {

  public var description: String {
    switch base {
    case is FuncSign, is UniversalSign:
      return "&(\(base))"
    default:
      return "&\(base)"
    }
  }

}
