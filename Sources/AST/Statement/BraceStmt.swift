import Basic

/// A block of statements.
public final class BraceStmt: Stmt, DeclContext {

  public init(stmts: [Stmt]) {
    self.stmts = stmts
    computeDeclCache()
  }

  /// The statements in the block.
  public var stmts: [Stmt] {
    didSet { computeDeclCache() }
  }

  public weak var parent: DeclContext?

  /// The block's range in the source.
  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

  public func decls(named name: String) -> AnySequence<NamedDecl> {
    return AnySequence(declCache[name, default: []])
  }

  public func firstDecl(named name: String) -> NamedDecl? {
    return declCache[name]?.first
  }

  /// A cache with the named declarations in this context.
  private var declCache: [String: [NamedDecl]] = [:]

  /// (Re)computes the declaration cache.
  private func computeDeclCache() {
    for case let decl as NamedDecl in stmts {
      declCache[decl.name, default: []].append(decl)

      // Look for additional declarations in the statement.
      if let loc = (decl as? StackAllocStmt)?.loc {
        declCache[loc.name, default: []].append(loc)
      }
    }
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
