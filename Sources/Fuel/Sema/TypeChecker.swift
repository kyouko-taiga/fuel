/// A static analysis pass that checks the type of every statement.
///
/// This pass assumes the semantic types of declarations and signatures has been fully realized.
public final class TypeChecker: Visitor {

  /// Creates a type checker pass.
  ///
  /// - Parameter context: The compiler context in which the pass is ran.
  public init(compilerContext: CompilerContext) {
    self.compilerContext = compilerContext
  }

  /// The compiler context in which the pass is ran.
  private let compilerContext: CompilerContext

  /// The current typing context.
  private var gamma: TypingContext = [:]

  /// The function being type-checked.
  ///
  /// This property is used during the AST traversal to access the declaration of the function
  /// being type-checked.
  private var funcDecl: FuncDecl!

  /// The type of the function being type-checked.
  private var funcType: FuncType!

  public func visit(_ node: Block) {
    // Type-check each statement in the block.
    var namedDecls: [NamedDecl] = []
    for stmt in node.stmts {
      stmt.accept(self)

      // Keep track of the named declarations so that they can be removed from the context later.
      if let decl = stmt as? NamedDecl {
        namedDecls.append(decl)
      }
    }

    // Remove from the context the names and memory locations that are scoped by the block.
    for decl in namedDecls {
      let symbol = Symbol(decl: decl)

      if decl is ScopeAllocStmt {
        let a = (gamma[symbol] as! LocationType).location
        gamma[a] = nil
      }

      gamma[symbol] = nil
    }
  }

  public func visit(_ node: CallStmt) {
    // Determine the type of the value callee.
    let funcType: FuncType
    let quantifiedParams: [QuantifiedParam]

    switch type(of: node.ident)?.canonical.base {
    case let ft as FuncType:
      funcType = ft
      quantifiedParams = []

    case let ut as UniversalType where ut.base is FuncType:
      funcType = ut.base as! FuncType
      quantifiedParams = ut.params

    case .some:
      compilerContext.report(message: "expression '\(node.ident)' is not a function")
        .set(location: node.ident.range?.lowerBound)
        .add(range: node.ident.range)
      return

    case nil:
      compilerContext.report(message: "cannot determine the type of expression '\(node.ident)'")
        .set(location: node.ident.range?.lowerBound)
        .add(range: node.ident.range)
      return
    }

    // List the assumptions that the function requires.
    var assumptions: [Assumption] = []
    for (argValue, paramType) in zip(node.args, funcType.params) {
      let base: TypeBase
      if let pt = paramType as? PackedType {
        base = pt.base
        assumptions.append(contentsOf: pt.assumptions)
      } else {
        base = paramType
      }

      if let symbol = (argValue as? IdentExpr)?.referredDecl?.symbol {
        assumptions.append((symbol, base))
      }
    }

    // Check whether the typing context justifies the required assumptions.
    guard let (substitutions, consumed) = justify(
        assumptions     : assumptions[0...],
        consumed        : [],
        quantifiedParams: quantifiedParams,
        substitutions   : [:])
    else {
      compilerContext.report(message: "unsatisfiable assumption set '\(assumptions)'")
        .set(location: node.ident.range?.lowerBound)
        .add(range: node.ident.range)
      return
    }

    // Subtract the consumed assumptions and insert the produced ones.
    for key in consumed {
      gamma[key] = nil
    }

    let output = funcType.output.canonical.substituting(substitutions)
    if let pt = output.base as? PackedType {
      gamma[Symbol(decl: node)] = QualifiedType(base: pt.base, qualifiers: output.qualifiers)

      for assumption in pt.assumptions {
        assert(gamma[assumption.key] == nil)
        gamma[assumption.key] = assumption.value
      }
    } else {
      gamma[Symbol(decl: node)] = output
    }
  }

  /// Determines whether the typing context justifies the specified set of assumptions.
  ///
  /// This method essentially checks whether the given assumptions are justified in the current
  /// typing context. Because assumptions may relate to universally quantified memory locations,
  /// the method must also compute a suitable instantiation of these "generic" locations.
  ///
  /// The method accounts for the use of linear (i.e., non-copyable) assumptions by keeping track
  /// of all used assumptions as it attempts to justify a new one.
  ///
  /// - Parameters:
  ///   - assumptions: The set of assumptions to justify.
  ///   - consumed: The set of assumptions that cannot be reused to justify new ones.
  ///   - quantifiedParams: The set of quantified parameter names.
  ///   - substitutions: A dictionary mapping universally quantified (i.e., "generic") locations
  ///     onto locations in the context.
  ///
  /// - Returns: If the given assumptions *are* justified, the method returns a pair containing a
  ///   dictionary mapping generic locations onto context locations and non-copyable subset of the
  ///   context that was used to justify the assumptions.
  private func justify(
    assumptions     : ArraySlice<Assumption>,
    consumed        : [TypingContext.Key],
    quantifiedParams: [QuantifiedParam],
    substitutions   : [Symbol: Symbol] = [:]
  ) -> (substitutions: [Symbol: Symbol], consumed: [TypingContext.Key])? {
    // Redeclare `consumed` as a mutable array.
    var consumed = consumed

    // Go through all assumptions and check whether they are satisfied by `context`.
    for i in assumptions.startIndex ..< assumptions.count {
      // Get the symbol on which the assumption is defined, using the substitutions we have guessed
      // so far if necessary.
      let symbol = substitutions[assumptions[i].key] ?? assumptions[i].key
      let rhs = assumptions[i].value.substituting(substitutions).canonical

      if let type = gamma[symbol] {
        assert(!quantifiedParams.contains(symbol.name ?? ""))

        // Make sure the assumption wasn't already framed out.
        guard !consumed.contains(symbol) else {
          return nil
        }

        // Check if the context supports the assumption, i.e., if it maps its symbol to a subtype.
        let lhs = type.canonical
        guard lhs.isSubtype(of: rhs) else {
          return nil
        }

        // Consume the assumption, unless it is copyable.
        if !lhs.qualifiers.contains(.copyable) {
          consumed.append(symbol)
        }
      } else if quantifiedParams.contains(symbol.name ?? "") {
        // If the requested symbol is a quantified parameter, we need to find an appropriate
        // substitution to match it with the concrete symbols of the context.
        let quant = quantifiedParams.filter({ $0 != symbol.name })
        for candidate in gamma where candidate.key.isReferringToLocation {
          // Extend the substitution map.
          var subst = substitutions
          subst[assumptions[i].key] = candidate.key

          // Check if the guess satisfies the requirements.
          if let result = justify(
              assumptions     : assumptions[i...],
              consumed        : consumed,
              quantifiedParams: quant,
              substitutions   : subst)
          {
            return result
          }
        }

        // If no substitution could be found, then the assumption is unsatisfied.
        return nil
      } else {
        // The assumption is missing from the context.
        return nil
      }
    }

    return (substitutions, consumed)
  }

  public func visit(_ node: FuncDecl) {
    // Skip the declaration if it's just a prologue.
    guard let body = node.body else {
      return
    }

    // The unqualified, canonical form of `declType` must be a function type or a universally
    // quantified function type. In the latter case, we can remove the universal quantier and
    // "instanciate" the function type.
    let declType: FuncType
    switch node.type?.canonical.base {
    case let ft as FuncType:
      declType = ft

    case let ut as UniversalType where ut.base is FuncType:
      declType = ut.base as! FuncType

    default:
      // Skip the declaration if it doesn't have a valid function type. This can be done silently,
      // as it should only happen when the type realizer was not able to evaluate an appropriate
      // type, which would have resulted in a diagnostic.
      return
    }

    // Setup the typing context to check the function's implementation.
    funcDecl = node
    funcType = declType

    for param in node.params {
      guard let paramType = param.type else {
        continue
      }

      let symbol = Symbol(decl: param)
      if let packedType = param.type as? PackedType {
        // Unpack the parameter type.
        gamma[symbol] = packedType.base

        // Check that each packed assumption either adds a new binding, or agrees with the context.
        for assumption in packedType.assumptions {
          if let ty = gamma[assumption.key], !ty.isEqual(to: assumption.value) {
            compilerContext.report(message: "type of parameter '\(param.name)' is inconsistent")
              .set(location: param.range?.lowerBound)
              .add(range: param.range)
          } else {
            gamma[assumption.key] = assumption.value
          }
        }
      } else {
        gamma[symbol] = paramType
      }
    }

    body.accept(self)
  }

  public func visit(_ node: FreeStmt) {
    // Determine the type of the identifier being deallocated.
    node.ident.accept(self)

    // Extract a capability `[a: loose τ]`.
    fatalError("todo")
  }

  public func visit(_ node: IfStmt) {
    // Visit the node's condition.
    node.cond.accept(self)

    // Check that the condition is a subtype of Bool.
    guard type(of: node.cond)?.isSubtype(of: BuiltinType.bool) ?? false else {
      compilerContext.report(message: "condition '\(node.cond)' should be Boolean")
        .set(location: node.cond.range?.lowerBound)
        .add(range: node.cond.range)
      return
    }

    // Type both branches of the statement individually.
    let context = gamma
    node.thenBody.accept(self)
    let thenContext = gamma

    gamma = context
    node.elseBody?.accept(self)

    // Join the resulting contexts.
    gamma = join(thenContext, gamma)
  }

  private func join(_ lhs: TypingContext, _ rhs: TypingContext) -> TypingContext {
    // Trivially, if both contexts are empty, then their join is an empty context.
    if lhs.isEmpty && rhs.isEmpty {
      return lhs
    }

    // FIXME: If the contexts' domains don't match, find a substitution for the new addresses to
    // heap-allocated in rhs that minimizes the difference.

    let lhsKeys = Set(lhs.keys)
    let rhsKeys = Set(rhs.keys)

    // Compute the join of all matching assumptions.
    let newContext = TypingContext(
      uniqueKeysWithValues: lhsKeys.intersection(rhsKeys).map({ key in
        (key: key, value: lhs[key]!.join(with: rhs[key]!))
      }))

    // FIXME: Create "uncertain" assumptions for each mismatching pair, to denote irreconcilable
    // outcomes. These will have to be consumed by dynamic checks.

    return newContext
  }

  public func visit(_ node: LoadStmt) {
    // Determine the type of the value reference.
    guard let nodeType = type(of: node.valueRef) else {
      compilerContext.report(message: "cannot determine the type of expression '\(node.valueRef)'")
        .set(location: node.valueRef.range?.lowerBound)
        .add(range: node.valueRef.range)
      return
    }

    // There are two cases to consider; the first is when the value reference is an identifier, the
    // second is when it's a member expression. In either case, the type of the value reference
    // should be `!a` for some location `a`.
    guard let a = (nodeType as? LocationType)?.location else {
      compilerContext.report(message: "invalid value reference '\(node.valueRef)'")
        .set(location: node.valueRef.range?.lowerBound)
        .add(range: node.valueRef.range)
      return
    }

    // Check if we hold a capability `[a: τ]`.
    guard let ty = gamma[a] else {
      compilerContext.report(message: "load requires missing capability '[\(a): τ]'")
        .set(location: node.range?.lowerBound)
        .add(range: node.valueRef.range)
      return
    }

    gamma[Symbol(decl: node)] = ty
  }

  public func visit(_ node: Module) {
    // Create an initial a typing context, with one entry for each type and function declaration.
    var context: TypingContext = [:]
    for decl in node.funcDecls {
      context[Symbol(decl: decl)] = decl.type
    }

    // Type-check each function declaration.
    for decl in node.funcDecls {
      gamma = context
      decl.accept(self)
    }
  }

  public func visit(_ node: ReturnStmt) {
    // Determine the type of the return value.
    guard let returnValueType = type(of: node.value) else {
      compilerContext.report(message: "cannot determine the type of '\(node.value)'")
        .set(location: node.value.range?.lowerBound)
        .add(range: node.value.range)
      return
    }

    // Check that the type of the return value matches the function's output type.
    let outputType: TypeBase
    let assumptions: TypingContext

    switch funcType.output {
    case let ext as PackedType:
      outputType = ext.base
      assumptions = ext.assumptions

    default:
      outputType = funcType.output
      assumptions = [:]
    }

    guard returnValueType.isSubtype(of: outputType) else {
      compilerContext.report(
        message:
          "cannot convert value of type '\(returnValueType)' " +
          "to expected type '\(outputType)'")
        .set(location: node.value.range?.lowerBound)
        .add(range: node.value.range)
      return
    }

    // Verity that the the environment contains the assumptions described by the function's
    // return type.
    for assumption in assumptions {
      guard let ty = gamma[assumption.key] else {
        compilerContext.report(
          message:
            "function return requires missing capability " +
            "'[\(assumption.key): \(assumption.value)]'")
          .set(location: node.range?.lowerBound)
          .add(range: node.range)
        continue
      }

      guard ty.isSubtype(of: assumption.value) else {
        compilerContext.report(
          message:
            "cannot convert capability '[\(assumption.key): \(ty)]' " +
            "to expected capability '[\(assumption.key): \(assumption.value)]'")
          .set(location: node.range?.lowerBound)
          .add(range: node.range)
        continue
      }
    }
  }

  public func visit(_ node: ScopeAllocStmt) {
    // Allocate a new location and create a capacity for it.
    let a = alloc()
    gamma[Symbol(decl: node)] = LocationType(location: a)
    gamma[a] = BuiltinType.junk
  }

  public func visit(_ node: StoreStmt) {
    // Determine the type of the value being stored.
    guard let valueType = type(of: node.value) else {
      compilerContext.report(message: "cannot determine the type of '\(node.value)'")
        .set(location: node.value.range?.lowerBound)
        .add(range: node.value.range)
      return
    }

    // Determine the type of the target identifier.
    guard let identSymbol = node.ident.referredDecl?.symbol,
          let identType = gamma[identSymbol]
    else {
      compilerContext.report(message: "cannot determine the type of '\(node.ident.name)'")
        .set(location: node.ident.range?.lowerBound)
        .add(range: node.ident.range)
      return
    }

    // The target identifier should have type `!a`.
    guard let a = (identType as? LocationType)?.location else {
      compilerContext.report(message: "cannot store to a value of type '\(identType)'")
        .set(location: node.range?.lowerBound)
        .add(range: node.range)
      return
    }

    // Check that we have the capability to write at `a`.
    guard gamma[a] != nil else {
      compilerContext.report(message: "store requires missing capability '[\(a): τ]'")
        .set(location: node.range?.lowerBound)
        .add(range: node.ident.range)
      return
    }

    gamma[a] = valueType
  }

  // MARK: Helper functions.

  private var nextLocationID = 0

  private func alloc() -> Symbol {
    let symbol = Symbol(id: nextLocationID, isReferringToLocation: true)
    nextLocationID += 1
    return symbol
  }

  /// Implements `Γ ⊢ e : τ`.
  private func type(of e: Expr) -> TypeBase? {
    switch e {
    case is BoolLit:
      return BuiltinType.bool

    case is IntLit:
      return BuiltinType.int

    case is VoidLit:
      return BuiltinType.void

    case is JunkLit:
      return BuiltinType.junk

    case let ident as IdentExpr:
      guard let decl = ident.referredDecl else {
        return nil
      }
      return gamma[Symbol(decl: decl)]

    case let member as MemberExpr:
      return nil

    default:
      return nil
    }
  }

}
