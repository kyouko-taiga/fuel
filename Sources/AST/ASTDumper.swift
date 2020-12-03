public final class ASTDumper<Output>: Visitor where Output: TextOutputStream {

  public init(output: Output) {
    self.output = output
  }

  /// The dumper's output.
  public var output: Output

  /// The dumper's current level of indentation.
  private var level = 0

  /// The leading spaces to display before each new line.
  private var lead: String { String(repeating: " ", count: level) }

  public func visit(_ node: AssumptionSign) {
    self << lead
    self << "(AssumpSign"

    self << "\n"
    withInc { node.ident.accept(self) }
    self << "\n"
    withInc { node.sign.accept(self) }

    self << ")"
  }

  public func visit(_ node: BoolLit) {
    self << lead
    self << "(BoolLit \"\(node.value)\")"
  }

  public func visit(_ node: BraceStmt) {
    self << lead
    self << "(BraceStmt"

    for stmt in node.stmts {
      self << "\n"
      withInc { stmt.accept(self) }
    }

    self << ")"
  }

  public func visit(_ node: CallStmt) {
    self << lead
    self << "(CallStmt \"\(node.symbol)\""

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
    self << "(IdentExpr \"\(node.name)\""

    if let decl = node.referredDecl {
      self << " \"\(decl.symbol)\""
    }

    self << ")"
  }

  public func visit(_ node: IdentSign) {
    self << lead
    self << "(IdentSign \"\(node.name)\""

    if let decl = node.referredDecl {
      self << " \"\(decl.symbol)\""
    }

    if let type = node.type {
      self << " type=\"\(type)\""
    }

    self << ")"
  }

  public func visit(_ node: IfStmt) {
    self << lead
    self << "(IfStmt"

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
    self << "(IntLit \"\(node.value)\")"
  }

  public func visit(_ node: JunkLit) {
    self << lead
    self << "(JunkLit)"
  }

  public func visit(_ node: FuncDecl) {
    self << lead
    self << "(FuncDecl \"\(node.symbol)\""

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
    self << "(FuncSign"

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
    self << "(FuncParamDecl \"\(node.symbol)\""
    self << ")"
  }

  public func visit(_ node: LoadStmt) {
    self << lead
    self << "(Load \"\(node.symbol)\""
    self << "\n"
    withInc { node.valueRef.accept(self) }
    self << ")"
  }

  public func visit(_ node: MemberExpr) {
    self << lead
    self << "(MemberExpr offset=\(node.offset)"
    self << "\n"
    withInc { node.base.accept(self) }
    self << ")"
  }

  public func visit(_ node: Module) {
    self << lead
    self << "(Module"
    self << " \"\(node.id)\""

    for decl in node.decls {
      self << "\n"
      withInc { decl.accept(self) }
    }

    self << ")"
  }

  public func visit(_ node: PackedSign) {
    self << lead
    self << "(PackedSign"

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

  public func visit(_ node: QuantifiedParamDecl) {
    self << lead
    self << "(QuantifiedParamDecl \"\(node.name)\""
    self << ")"
  }

  public func visit(_ node: ReturnStmt) {
    self << lead
    self << "(ReturnStmt"
    self << "\n"
    withInc { node.value.accept(self) }
    self << ")"
  }

  public func visit(_ node: ScopeAllocStmt) {
    self << lead
    self << "(ScopeAlloc \"\(node.symbol)\""
    self << "\n"
    withInc { node.sign.accept(self) }
    self << ")"
  }

  public func visit(_ node: StoreStmt) {
    self << lead
    self << "(StoreStmt"
    self << "\n"
    withInc { node.value.accept(self) }
    self << "\n"
    withInc { node.ident.accept(self) }
    self << ")"
  }

  public func visit(_ node: TupleSign) {
    self << lead
    self << "(TupleSign"

    if let type = node.type {
      self << " type=\"\(type)\""
    }

    for member in node.members {
      self << "\n"
      withInc { member.accept(self) }
    }

    self << ")"
  }

  public func visit(_ node: UniversalSign) {
    self << lead
    self << "(UniversalSign "

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
    self << "(VoidLit)"
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
