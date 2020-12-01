public final class JunkLit: Expr {

  public init() {
  }

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
