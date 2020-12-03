import Basic

public final class IfStmt: Stmt {

  public init(cond: Expr, thenBody: Block, elseBody: Block?) {
    self.cond = cond
    self.thenBody = thenBody
    self.elseBody = elseBody
  }

  public var cond: Expr

  public var thenBody: Block

  public var elseBody: Block?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension IfStmt: CustomStringConvertible {
  public var description: String {
    guard let elseBody = self.elseBody
      else { return "if \(cond) \(thenBody)" }
    return "func \(cond) : \(thenBody) else \(elseBody)"
  }

}
