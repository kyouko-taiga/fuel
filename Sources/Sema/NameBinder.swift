import AST

/// A static analysis pass that binds identifiers to their declaration contexts.
///
/// Name binding is the first pass of the static analysis pipeline, typically ran immeidiately
/// after parsing. It links value and type identifiers to their respective declaration.
public final class NameBinder: Visitor {

  /// Creates a name binder pass.
  ///
  /// - Parameter astContext: The AST context in which the pass is ran.
  public init(astContext: ASTContext) {
    self.astContext = astContext
  }

  /// The AST context in which the pass is ran.
  public let astContext: ASTContext

  /// The current declaration context.
  private var declContext: DeclContext?

  /// A flag that is set when the pass raised an error.
  private var hasErrors = false

  public func visit(_ node: Module) {
    hasErrors = false
    node.stateGoals.removeAll()

    declContext = node
    traverse(node)

    if !hasErrors {
      node.stateGoals.insert(.namesResolved)
    }
  }

  public func visit(_ node: BraceStmt) {
    node.parent = declContext
    declContext = node
    traverse(node)
    declContext = node.parent
  }

  public func visit(_ node: UniversalSign) {
    node.parent = declContext
    declContext = node
    traverse(node)
    declContext = node.parent
  }

  public func visit(_ node: FuncDecl) {
    node.declContext = declContext
    checkDuplicateDecl(node)

    node.parent = declContext
    declContext = node
    traverse(node)
    declContext = node.parent
  }

  public func visit(_ node: QuantifiedParamDecl) {
    node.declContext = declContext
    checkDuplicateDecl(node)
    traverse(node)
  }

  public func visit(_ node: LocDecl) {
    node.declContext = declContext
    checkDuplicateDecl(node)
    traverse(node)
  }

  public func visit(_ node: ScopeAllocStmt) {
    node.declContext = declContext
    checkDuplicateDecl(node)
    traverse(node)
  }

  public func visit(_ node: LoadStmt) {
    node.declContext = declContext
    checkDuplicateDecl(node)
    traverse(node)
  }

  public func visit(_ node: CallStmt) {
    node.declContext = declContext
    checkDuplicateDecl(node)
    traverse(node)
  }

  public func visit(_ node: IdentExpr) {
    traverse(node)

    if let decl = declContext?.lookup(name: node.name) {
      node.referredDecl = decl
    } else {
      hasErrors = true
      astContext.report(message: "cannot find '\(node.name)' in scope")
        .set(location: node.range?.lowerBound)
        .add(range: node.range)
    }
  }

  public func visit(_ node: IdentSign) {
    traverse(node)

    let decl = declContext?.lookup(name: node.name)
    switch decl {
    case let typeDecl as NominalTypeDecl:
      node.referredDecl = typeDecl

    case .some:
      hasErrors = true
      astContext.report(message: "'\(node.name)' is not a type")
        .set(location: node.range?.lowerBound)
        .add(range: node.range)

    case nil:
      hasErrors = true
      astContext.report(message: "cannot find '\(node.name)' in scope")
        .set(location: node.range?.lowerBound)
        .add(range: node.range)
    }
  }

  private func checkDuplicateDecl(_ node: NamedDecl) {
    if node.declContext!.decls(named: node.name).contains(where: { $0 !== node }) {
      hasErrors = true
      astContext.report(message: "duplicate declaration '\(node.name)'")
        .set(location: node.range?.lowerBound)
        .add(range: node.range)
    }
  }

}
