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

    let funcTy: FuncType?
    switch node.sign.type?.bareType {
    case let ty as FuncType:
      funcTy = ty

    case let ty as QuantifiedType where (ty.quantifier == .universal) && (ty.base is FuncType):
      // swiftlint:disable:next force_cast
      funcTy = (ty.base as! FuncType)

    default:
      funcTy = nil
      hasErrors = true
      astContext.report(message: "'\(node.sign)' is not a function type")
        .set(location: node.sign.range?.lowerBound)
        .add(range: node.sign.range)
    }

    if funcTy != nil {
      node.type = node.sign.type
      if node.params.count != funcTy!.params.count {
        hasErrors = true
        astContext.report(message: "incompatible function signature")
          .set(location: node.sign.range?.lowerBound)
          .add(range: node.sign.range)
      }

      for (paramDecl, paramType) in zip(node.params, funcTy!.params) {
        paramDecl.type = paramType
      }
    }

    node.body?.accept(self)
  }

  public func visit(_ node: QuantifiedSign) {
    traverse(node)

    guard let base = node.base.type else { return }
    assert(base.quals.isEmpty)

    node.type = QualType(
      bareType: astContext.quantifiedType(
        quantifier: node.quantifier,
        params: node.params.map({ $0.name }),
        base: base.bareType))
  }

  public func visit(_ node: FuncSign) {
    traverse(node)

    let params = node.params.map({ $0.type ?? errorType })
    let output = node.output.type ?? errorType
    node.type = QualType(bareType: astContext.funcType(params: params, output: output))
  }

  public func visit(_ node: LocSign) {
    traverse(node)

    if let decl = node.location.referredDecl {
      node.type = QualType(bareType: astContext.locType(location: decl.symbol))
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
      let sym = decl.symbol
      guard assumptions[sym] == nil else {
        hasErrors = true
        astContext.report(message: "inconsistent assumption")
          .set(location: assumption.range?.lowerBound)
          .add(range: assumption.range)
        continue
      }

      // Notice that assumptions with unrealized signatures are given an error type, so that they
      // can still appear in the context.
      assumptions[sym] = assumption.sign.type ?? errorType
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
