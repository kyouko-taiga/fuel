public final class CallStmt: Stmt, NamedDecl {

  public init(name: String, ident: IdentExpr, args: [Expr]) {
    self.name = name
    self.ident = ident
    self.args = args
  }

  public var name: String

  public var ident: IdentExpr

  public var args: [Expr]

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension CallStmt: CustomStringConvertible {

  public var description: String {
    if args.isEmpty {
      return "\(name) = call \(ident)"
    } else {
      let tail = args.map(String.init(describing:)).joined(separator: ", ")
      return "\(name) = call \(ident), \(tail)"
    }
  }

}
