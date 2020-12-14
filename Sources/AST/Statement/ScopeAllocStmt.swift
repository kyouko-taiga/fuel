import Basic

public final class ScopeAllocStmt: Stmt, NamedDecl {

  public init(name: String, sign: TypeSign, loc: LocDecl? = nil) {
    self.name = name
    self.sign = sign
    self.loc = loc
  }

  public var name: String

  public var sign: TypeSign

  /// The location of the cell allocated by this statement.
  public var loc: LocDecl?

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension ScopeAllocStmt: CustomStringConvertible {

  public var description: String {
    if let loc = self.loc {
      return "\(name) = salloc \(sign) at \(loc.name)"
    } else {
      return "\(name) = salloc \(sign)"
    }
  }

}
