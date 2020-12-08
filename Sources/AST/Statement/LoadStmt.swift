import Basic

public final class LoadStmt: Stmt, NamedDecl {

  public init(name: String, lvalue: LValueExpr) {
    self.name = name
    self.lvalue = lvalue
  }

  public var name: String

  public var lvalue: LValueExpr

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension LoadStmt: CustomStringConvertible {

  public var description: String {
    return "\(name) = load \(lvalue)"
  }

}
