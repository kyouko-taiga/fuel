public final class ASTDumper<Output>: Visitor where Output: TextOutputStream {

  public init(output: Output) {
    self.output = output
  }

  /// The dumper's output.
  public var output: Output

  /// The dumper's current level of indentation.
  private var level = 0

  /// The leading spaces to display before each new line.
  private var lead: String { String(repeating: "  ", count: level) }

  public func visit(_ node: AddrStmt) {
    self << lead
    self << "(\(type(of: node)) \"\(node.name)\""
    self << "\n"
    withInc { node.path.accept(self) }
    self << ")"
  }

  public func visit(_ node: AssumptionSign) {
    self << lead
    self << "(\(type(of: node))"

    self << "\n"
    withInc { node.ident.accept(self) }
    self << "\n"
    withInc { node.sign.accept(self) }

    self << ")"
  }

  public func visit(_ node: BoolLit) {
    self << lead
    self << "(\(type(of: node)) \"\(node.value)\")"
  }

  public func visit(_ node: BraceStmt) {
    self << lead
    self << "(\(type(of: node))"

    for stmt in node.stmts {
      self << "\n"
      withInc { stmt.accept(self) }
    }

    self << ")"
  }

  public func visit(_ node: CallStmt) {
    self << lead
    self << "(\(type(of: node)) \"\(node.name)\""

    self << "\n"
    withInc { node.ident.accept(self) }

    for arg in node.args {
      self << "\n"
      withInc { arg.accept(self) }
    }

    self << ")"
  }

  public func visit(_ node: IdentExpr) {
    self << lead
    self << "(\(type(of: node)) \"\(node.name)\""

    self << ")"
  }

  public func visit(_ node: IdentSign) {
    self << lead
    self << "(\(type(of: node)) \"\(node.name)\""

    if let type = node.type {
      self << " type=\"\(type)\""
    }

    self << ")"
  }

  public func visit(_ node: IfStmt) {
    self << lead
    self << "(\(type(of: node))"

    self << "\n"
    withInc { node.cond.accept(self) }

    self << "\n"
    withInc { node.thenBody.accept(self) }

    if let elseBody = node.elseBody {
      self << "\n"
      withInc { elseBody.accept(self) }
    }

    self << ")"
  }

  public func visit(_ node: IntLit) {
    self << lead
    self << "(\(type(of: node)) \"\(node.value)\")"
  }

  public func visit(_ node: FuncDecl) {
    self << lead
    self << "(\(type(of: node)) \"\(node.name)\""

    self << "\n"
    withInc { node.sign.accept(self) }

    if let body = node.body {
      self << "\n"
      withInc { body.accept(self) }
    }

    self << ")"
  }

  public func visit(_ node: FuncSign) {
    self << lead
    self << "(\(type(of: node))"

    if let type = node.type {
      self << " type=\"\(type)\""
    }

    for param in node.params {
      self << "\n"
      withInc { param.accept(self) }
    }

    self << "\n"
    withInc { node.output.accept(self) }

    self << ")"
  }

  public func visit(_ node: FuncParamDecl) {
    self << lead
    self << "(\(type(of: node)) \"\(node.name)\""
    self << ")"
  }

  public func visit(_ node: FreeStmt) {
    self << lead
    self << "(\(type(of: node))"
    self << "\n"
    withInc { node.expr.accept(self) }
    self << ")"
  }

  public func visit(_ node: LoadStmt) {
    self << lead
    self << "(\(type(of: node)) \"\(node.name)\""
    self << "\n"
    withInc { node.lvalue.accept(self) }
    self << ")"
  }

  public func visit(_ node: LocDecl) {
    self << lead
    self << "(\(type(of: node)) \"\(node.name)\""
    self << ")"
  }

  public func visit(_ node: LocSign) {
    self << lead
    self << "(\(type(of: node))"

    if let type = node.type {
      self << " type=\"\(type)\""
    }

    self << "\n"
    withInc { node.location.accept(self) }
    self << ")"
  }

  public func visit(_ node: MemberExpr) {
    self << lead
    self << "(\(type(of: node)) offset=\(node.offset)"
    self << "\n"
    withInc { node.base.accept(self) }
    self << ")"
  }

  public func visit(_ node: Module) {
    self << lead
    self << "(\(type(of: node))"
    self << " \"\(node.id)\""

    for decl in node.allDecls {
      self << "\n"
      withInc { decl.accept(self) }
    }

    self << ")"
  }

  public func visit(_ node: BuiltinTypeDecl) {
    self << lead
    self << "(\(type(of: node)) \"\(node.name)\")"
  }

  public func visit(_ node: BundledSign) {
    self << lead
    self << "(\(type(of: node))"

    if let type = node.type {
      self << " type=\"\(type)\""
    }

    self << "\n"
    withInc { node.base.accept(self) }

    for assump in node.assumptions {
      self << "\n"
      withInc { assump.accept(self) }
    }

    self << ")"
  }

  public func visit(_ node: QualSign) {
    self << lead
    self << "(\(type(of: node))"

    if let type = node.type {
      self << " type=\"\(type)\""
    }
    self << " qualifiers=\(node.qualifiers)"

    self << "\n"
    withInc { node.base.accept(self) }

    self << ")"
  }

  public func visit(_ node: QuantifiedParamDecl) {
    self << lead
    self << "(\(type(of: node)) \"\(node.name)\""
    self << ")"
  }

  public func visit(_ node: ReturnStmt) {
    self << lead
    self << "(\(type(of: node))"
    self << "\n"
    withInc { node.value.accept(self) }
    self << ")"
  }

  public func visit(_ node: AllocStmt) {
    self << lead
    self << "(\(type(of: node)) \"\(node.name)\""

    switch node.segment {
    case .stack:
      self << " segment=\"stack\""
    case .heap:
      self << " segment=\"heap\""
    }

    self << "\n"
    withInc { node.sign.accept(self) }
    self << ")"
  }

  public func visit(_ node: StoreStmt) {
    self << lead
    self << "(\(type(of: node))"
    self << "\n"
    withInc { node.rvalue.accept(self) }
    self << "\n"
    withInc { node.lvalue.accept(self) }
    self << ")"
  }

  public func visit(_ node: TupleSign) {
    self << lead
    self << "(\(type(of: node))"

    if let type = node.type {
      self << " type=\"\(type)\""
    }

    for member in node.members {
      self << "\n"
      withInc { member.accept(self) }
    }

    self << ")"
  }

  public func visit(_ node: QuantifiedSign) {
    self << lead
    self << "(\(type(of: node))"

    switch node.quantifier {
    case .universal:
      self << " quantifier=\"universal\""
    case .existential:
      self << " quantifier=\"existential\""
    }

    if let type = node.type {
      self << " type=\"\(type)\""
    }

    for param in node.params {
      self << "\n"
      withInc { param.accept(self) }
    }

    self << "\n"
    node.base.accept(self)

    self << ")"
  }

  public func visit(_ node: VoidLit) {
    self << lead
    self << "(\(type(of: node)))"
  }

  func withInc(_ action: () -> Void) {
    level += 1
    action()
    level -= 1
  }

  static func << (dumper: ASTDumper, item: Any?) {
    dumper.output.write(item.map(String.init(describing:)) ?? "_")
  }

}
