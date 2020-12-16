import Basic

public final class FreeStmt: Stmt {

  public init(expr: Expr) {
    self.expr = expr
  }

  public var expr: Expr

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension FreeStmt: CustomStringConvertible {

  public var description: String {
    return "free \(expr)"
  }

}
