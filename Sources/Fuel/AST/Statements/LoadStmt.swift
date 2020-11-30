public final class LoadStmt: Stmt, NamedDecl {

  public init(name: String, valueRef: Expr) {
    self.name = name
    self.valueRef = valueRef
  }

  public var name: String

  public var valueRef: Expr

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension LoadStmt: CustomStringConvertible {

  public var description: String {
    return "\(name) = load \(valueRef)"
  }

}
