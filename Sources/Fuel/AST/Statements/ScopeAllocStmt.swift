public final class ScopeAllocStmt: Stmt, NamedDecl {

  public init(name: String, sign: TypeSign) {
    self.name = name
    self.sign = sign
  }

  public var name: String

  public var sign: TypeSign

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension ScopeAllocStmt: CustomStringConvertible {

  public var description: String {
    return "\(name) = salloc \(sign)"
  }

}
