import AST

/// A static analysis pass that binds identifiers to their declaration contexts.
///
/// Name binding is the first pass of the static analysis pipeline, typically ran immeidiately
/// after parsing. It links value and type identifiers to their respective declaration.
public final class NameBinder: Visitor {

  /// Creates a name binder pass.
  ///
  /// - Parameter context: The compiler context in which the pass is ran.
  public init(compilerContext: CompilerContext) {
    self.compilerContext = compilerContext
  }

  /// The compiler context in which the pass is ran.
  private let compilerContext: CompilerContext

  /// The current declaration context.
  private var declContext: DeclContext?

  public func visit(_ node: Module) {
    declContext = node
    traverse(node)
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
      compilerContext.report(message: "cannot find '\(node.name)' in scope")
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
      compilerContext.report(message: "'\(node.name)' is not a type")
        .set(location: node.range?.lowerBound)
        .add(range: node.range)

    case nil:
      compilerContext.report(message: "cannot find '\(node.name)' in scope")
        .set(location: node.range?.lowerBound)
        .add(range: node.range)
    }
  }

  private func checkDuplicateDecl(_ node: NamedDecl) {
    if node.declContext!.decls.contains(where: { ($0 !== node) && ($0.name == node.name) }) {
      compilerContext.report(message: "duplicate declaration '\(node.name)'")
        .set(location: node.range?.lowerBound)
        .add(range: node.range)
    }
  }

}
