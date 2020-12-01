public final class IntLit: Expr {

  public init(value: Int) {
    self.value = value
  }

  public var value: Int

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension IntLit: CustomStringConvertible {

  public var description: String {
    return String(describing: value)
  }

}
