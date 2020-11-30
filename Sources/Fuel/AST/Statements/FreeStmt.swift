public final class FreeStmt: Stmt {

  public init(ident: IdentExpr) {
    self.ident = ident
  }

  public var ident: IdentExpr

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension FreeStmt: CustomStringConvertible {

  public var description: String {
    return "free \(ident)"
  }

}
