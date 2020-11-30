public final class JunkLit: Expr {

  public init() {
  }

  public let type: TypeBase? = BuiltinType.junk

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension JunkLit: CustomStringConvertible {

  public var description: String {
    return "junk"
  }

}
