import Basic

public final class AddrStmt: Stmt, NamedDecl {

  public init(name: String, path: MemberExpr) {
    self.name = name
    self.path = path
  }

  public var name: String

  public var path: MemberExpr

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension AddrStmt: CustomStringConvertible {

  public var description: String {
    return "\(name) = addr \(path)"
  }

}
