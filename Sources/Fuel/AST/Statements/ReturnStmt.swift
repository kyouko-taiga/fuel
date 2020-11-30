public final class ReturnStmt: Stmt {

  public init(value: Expr) {
    self.value = value
  }

  public var value: Expr

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension ReturnStmt: CustomStringConvertible {

  public var description: String {
    return "return \(value)"
  }

}
