/// An AST visitor.
public protocol Visitor {

  func visit(_ node: Module)

  func visit(_ node: FuncDecl)

  func visit(_ node: FuncParamDecl)

  func visit(_ node: QuantifiedParamDecl)

  func visit(_ node: LocDecl)

  func visit(_ node: BraceStmt)

  func visit(_ node: AllocStmt)

  func visit(_ node: FreeStmt)

  func visit(_ node: StoreStmt)

  func visit(_ node: LoadStmt)

  func visit(_ node: CallStmt)

  func visit(_ node: AddrStmt)

  func visit(_ node: ReturnStmt)

  func visit(_ node: IfStmt)

  func visit(_ node: QuantifiedSign)

  func visit(_ node: QualSign)

  func visit(_ node: FuncSign)

  func visit(_ node: TupleSign)

  func visit(_ node: PointerSign)

  func visit(_ node: IdentSign)

  func visit(_ node: LocSign)

  func visit(_ node: BundledSign)

  func visit(_ node: AssumptionSign)

  func visit(_ node: IdentExpr)

  func visit(_ node: MemberExpr)

  func visit(_ node: BoolLit)

  func visit(_ node: IntLit)

  func visit(_ node: VoidLit)

}

extension Visitor {

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: Module) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: Module) {
    node.allDecls.forEach({ $0.accept(self) })
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: FuncDecl) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: FuncDecl) {
    node.sign.accept(self)
    node.body?.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: FuncParamDecl) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: FuncParamDecl) {
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: QuantifiedParamDecl) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: QuantifiedParamDecl) {
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: LocDecl) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: LocDecl) {
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: NominalTypeDecl) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: NominalTypeDecl) {
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: BraceStmt) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: BraceStmt) {
    node.stmts.forEach({ $0.accept(self) })
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: AllocStmt) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: AllocStmt) {
    node.sign.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: FreeStmt) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: FreeStmt) {
    node.expr.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: StoreStmt) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: StoreStmt) {
    node.lvalue.accept(self)
    node.rvalue.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: LoadStmt) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: LoadStmt) {
    node.lvalue.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: CallStmt) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: CallStmt) {
    node.ident.accept(self)
    node.args.forEach({ $0.accept(self) })
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: AddrStmt) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: AddrStmt) {
    node.path.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: ReturnStmt) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: ReturnStmt) {
    node.value.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: IfStmt) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: IfStmt) {
    node.cond.accept(self)
    node.thenBody.accept(self)
    node.elseBody?.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: QuantifiedSign) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: QuantifiedSign) {
    node.params.forEach({ $0.accept(self) })
    node.base.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: QualSign) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: QualSign) {
    node.base.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: FuncSign) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: FuncSign) {
    node.params.forEach({ $0.accept(self) })
    node.output.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: TupleSign) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: TupleSign) {
    node.members.forEach({ $0.accept(self) })
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: PointerSign) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  @inlinable public func traverse(_ node: PointerSign) {
    node.base.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: IdentSign) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: IdentSign) {
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: LocSign) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  @inlinable public func traverse(_ node: LocSign) {
    node.location.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: BundledSign) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: BundledSign) {
    node.base.accept(self)
    node.assumptions.forEach({ $0.accept(self) })
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: AssumptionSign) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: AssumptionSign) {
    node.ident.accept(self)
    node.sign.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: IdentExpr) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: IdentExpr) {
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: MemberExpr) {
    traverse(node)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to traverse.
  @inlinable public func traverse(_ node: MemberExpr) {
    node.base.accept(self)
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: BoolLit) {
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: IntLit) {
  }

  /// Traverses the specified node, visiting each of its children.
  ///
  /// - Parameter node: The node to visit.
  public func visit(_ node: VoidLit) {
  }

}
