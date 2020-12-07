import Basic

public final class StoreStmt: Stmt {

  public init(rvalue: Expr, lvalue: LValueExpr) {
    self.rvalue = rvalue
    self.lvalue = lvalue
  }

  public var rvalue: Expr

  public var lvalue: LValueExpr

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension StoreStmt: CustomStringConvertible {

  public var description: String {
    return "store \(rvalue), \(lvalue)"
  }

}
