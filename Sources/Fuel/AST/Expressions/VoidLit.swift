public final class VoidLit: Expr {

  public init() {
  }

  public let type: TypeBase? = BuiltinType.void

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension VoidLit: CustomStringConvertible {

  public var description: String {
    return "void"
  }

}
