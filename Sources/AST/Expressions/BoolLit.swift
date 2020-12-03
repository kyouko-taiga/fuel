import Basic

public final class BoolLit: Expr {

  public init(value: Bool) {
    self.value = value
  }

  public var value: Bool

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension BoolLit: CustomStringConvertible {

  public var description: String {
    return String(describing: value)
  }

}
