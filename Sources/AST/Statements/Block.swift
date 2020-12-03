import Basic

/// A block of statements.
public final class Block: DeclContext {

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

}

extension Block: MutableCollection {

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

extension Block: CustomStringConvertible {

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
