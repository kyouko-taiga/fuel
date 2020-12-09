import Basic

/// A block of statements.
public final class BraceStmt: Stmt, DeclContext {

  public init(stmts: [Stmt]) {
    self.stmts = stmts
  }

  /// The statements in the block.
  public var stmts: [Stmt]

  public weak var parent: DeclContext?

  public var decls: [NamedDecl] { stmts.compactMap({ $0 as? NamedDecl }) }

  /// The block's range in the source.
  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

  public func decls(named name: String) -> AnySequence<NamedDecl> {
    return AnySequence(stmts.compactMap({ (stmt: Stmt) -> NamedDecl? in
      if let decl = stmt as? NamedDecl, decl.name == name {
        return decl
      } else {
        return nil
      }
    }))
  }

  public func firstDecl(named name: String) -> NamedDecl? {
    for case let decl as NamedDecl in stmts where decl.name == name {
      return decl
    }
    return nil
  }

}

extension BraceStmt: MutableCollection {

  public var startIndex: Int { 0 }

  public var endIndex: Int { stmts.count }

  public func index(after i: Int) -> Int {
    return i + 1
  }

  public subscript(position: Int) -> Stmt {
    get { stmts[position] }
    set { stmts[position] = newValue }
  }

}

extension BraceStmt: CustomStringConvertible {

  public var description: String {
    let body = stmts
      .map({ stmt in
        String(describing: stmt)
          .split(separator: "\n")
          .map({ "  \($0)" })
          .joined(separator: "\n")
          + "\n"
      })
      .joined()
    return "{\n" + body + "}"
  }

}
