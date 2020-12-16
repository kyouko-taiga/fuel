import Basic

public final class FreeStmt: Stmt {

  public init(lvalue: LValueExpr) {
    self.lvalue = lvalue
  }

  public var lvalue: LValueExpr

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension FreeStmt: CustomStringConvertible {

  public var description: String {
    return "free \(lvalue)"
  }

}
