public final class StoreStmt: Stmt {

  public init(value: Expr, ident: IdentExpr) {
    self.value = value
    self.ident = ident
  }

  public var value: Expr

  public var ident: IdentExpr

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension StoreStmt: CustomStringConvertible {

  public var description: String {
    return "store \(value), \(ident)"
  }

}
