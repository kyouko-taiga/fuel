import AST

/// A pass that builds the semantic type of declarations and signatures.
public final class TypeRealizer: Visitor {

  /// Creates a type realizer pass.
  ///
  /// - Parameter astContext: The AST context in which the pass is ran.
  public init(astContext: ASTContext) {
    self.astContext = astContext
    self.errorType = astContext.errorType.qualified()
  }

  /// The AST context in which the pass is ran.
  private let astContext: ASTContext

  /// An error type.
  private let errorType: QualType

  /// A flag that is set when the pass raised an error.
  private var hasErrors = false

  public func visit(_ node: Module) {
    hasErrors = false
    node.stateGoals.subtract([.typesResolved, .typeChecked])

    traverse(node)

    if !hasErrors {
      node.stateGoals.insert(.typesResolved)
    }
  }

  public func visit(_ node: FuncDecl) {
    node.sign.accept(self)

    let funcType: FuncType?
    switch node.sign.type?.bareType {
    case let ft as FuncType:
      funcType = ft

    case let ut as UniversalType where ut.base is FuncType:
      // swiftlint:disable:next force_cast
      funcType = (ut.base as! FuncType)

    default:
      funcType = nil
      hasErrors = true
      astContext.report(message: "'\(node.sign)' is not a function type")
        .set(location: node.sign.range?.lowerBound)
        .add(range: node.sign.range)
    }

    if funcType != nil {
      node.type = node.sign.type
      if node.params.count != funcType!.params.count {
        hasErrors = true
        astContext.report(message: "incompatible function signature")
          .set(location: node.sign.range?.lowerBound)
          .add(range: node.sign.range)
      }

      for (paramDecl, paramType) in zip(node.params, funcType!.params) {
        paramDecl.type = paramType
      }
    }

    node.body?.accept(self)
  }

  public func visit(_ node: UniversalSign) {
    traverse(node)

    guard let base = node.base.type else { return }
    node.type = QualType(
      bareType: astContext.universalType(
        base: base.bareType,
        params: node.params.map({ $0.name })))
  }

  public func visit(_ node: FuncSign) {
    traverse(node)

    let params = node.params.map({ $0.type ?? errorType })
    let output = node.output.type ?? errorType
    node.type = QualType(bareType: astContext.funcType(params: params, output: output))
  }

  public func visit(_ node: LocationSign) {
    traverse(node)

    if let decl = node.location.referredDecl {
      node.type = QualType(bareType: astContext.locationType(location: Symbol(decl: decl)))
    }
  }

  public func visit(_ node: BundledSign) {
    // Traverse the node to realize the type of the base signature and that of each assumption.
    traverse(node)

    // Skip the node if we were not able to realize the type of its base signature.
    guard let base = node.base.type else { return }

    // Encode the set of assumptions into a typing context that maps each quantified parameter onto
    // its assumed type τ.
    var assumptions: TypingContext = [:]
    for assumption in node.assumptions {
      // Skip the assumption if it refers to an undefined identifier.
      guard let decl = assumption.ident.referredDecl else {
        continue
      }

      // Check that the assumption is not inconsistent with the ones already realized.
      let symbol = Symbol(decl: decl)
      guard assumptions[symbol] == nil else {
        hasErrors = true
        astContext.report(message: "inconsistent assumption")
          .set(location: assumption.range?.lowerBound)
          .add(range: assumption.range)
        continue
      }

      // Notice that assumptions with unrealized signatures are given an error type, so that they
      // can still appear in the context.
      assumptions[symbol] = assumption.sign.type ?? errorType
    }

    // Build the extended type.
    node.type = QualType(
      bareType: astContext.bundledType(base: base.bareType, assumptions: assumptions))
  }

  public func visit(_ node: TupleSign) {
    // Traverse the node to realize the type of each member.
    traverse(node)

    // Build the tuple type.
    node.type = QualType(
      bareType: astContext.tupleType(members: node.members.map({ $0.type ?? errorType })))
  }

  public func visit(_ node: IdentSign) {
    traverse(node)

    if let bareType = node.referredDecl?.type {
      node.type = QualType(bareType: bareType)
    }
  }

}
