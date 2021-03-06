import AST
import Basic

/// A static analysis pass that checks the type of every statement.
///
/// This pass assumes the semantic types of declarations and signatures has been fully realized.
public final class TypeChecker: Visitor {

  /// Creates a type checker pass.
  ///
  /// - Parameter astContext: The AST context in which the pass is ran.
  public init(astContext: ASTContext) {
    self.astContext = astContext
    self.anyType = astContext.builtin.any.qualified()
  }

  /// The AST context in which the pass is ran.
  public let astContext: ASTContext

  /// The current typing context.
  private var typingContext: TypingContext = [:]

  /// The function being type-checked.
  ///
  /// This property is used during the AST traversal to access the declaration of the function
  /// being type-checked.
  private var funcDecl: FuncDecl!

  /// The type of the function being type-checked.
  private var funcType: FuncType!

  /// The unqualified `Any` type.
  private let anyType: QualType

  /// A flag that is set when the pass raised an error.
  @usableFromInline var hasErrors = false

  public func visit(_ node: Module) {
    hasErrors = false
    node.stateGoals.subtract([.typeChecked])

    // Type-check each function declaration.
    for decl in node.funcDecls.values {
      typingContext = [:]
      typeCheck(decl)
    }

    if !hasErrors {
      node.stateGoals.insert(.typeChecked)
    }
  }

  /// Visits the given node with the specified type checking method.
  ///
  /// This method is used internally to factorize error handling.
  @inlinable public func visit<N>(_ node: N, with checker: (N) throws -> Void) {
    do {
      try checker(node)
    } catch let error as TypeError {
      hasErrors = true
      error.report(in: astContext)
    } catch {
      fatalError("unreachable")
    }
  }

  public func visit(_ node: BraceStmt) {
    typeCheck(node)
  }

  public func visit(_ node: CallStmt) {
    visit(node, with: typeCheck)
  }

  public func visit(_ node: IfStmt) {
    visit(node, with: typeCheck)
  }

  public func visit(_ node: LoadStmt) {
    visit(node, with: typeCheck)
  }

  public func visit(_ node: ReturnStmt) {
    visit(node, with: typeCheck)
  }

  public func visit(_ node: AllocStmt) {
    typeCheck(node)
  }

  public func visit(_ node: FreeStmt) {
    visit(node, with: typeCheck)
  }

  public func visit(_ node: StoreStmt) {
    visit(node, with: typeCheck)
  }

  // MARK: Type checking methods

  public func typeCheck(_ node: FuncDecl) {
    // Skip the declaration if it's just a prologue.
    guard let body = node.body else { return }

    // If the declaration has a universal type, then we can simply remove the quantifier to
    // "instanciate" each quantified parameter.
    guard let declType = node.bareFuncType else {
      // Skip the declaration if it doesn't have a valid function type. This can be done silently,
      // as it should only happen when the type realizer was not able to evaluate an appropriate
      // type, which would have resulted in a diagnostic.
      return
    }

    // Setup the typing context to check the function's implementation.
    funcDecl = node
    funcType = declType

    for param in node.params {
      // Slip the declaration if it doesn't have a valid type.
      guard let paramType = param.type else { continue }

      // Insert the parameter's type into the typing context.
      let sym = param.symbol
      if let (tau, eta) = param.type?.opened {
        // Unbundle the type.
        typingContext[sym] = tau

        // Check that each packed assumption either adds a new binding, or agrees with the context.
        for assumption in eta {
          let prevAssumpType = typingContext[assumption.key]
          if (prevAssumpType != nil) && (prevAssumpType != assumption.value) {
            hasErrors = true
            TypeError
              .inconsistentAssumption(assump: assumption, range: param.range)
              .report(in: astContext)
          } else {
            typingContext[assumption.key] = assumption.value
          }
        }
      } else {
        typingContext[sym] = paramType
      }
    }

    body.accept(self)
  }

  public func typeCheck(_ node: BraceStmt) {
    var localSymbols: [Symbol] = []
    var stackSymbols: [Symbol] = []

    for stmt in node.stmts {
      // Type-check the statement.
      stmt.accept(self)

      // Keep track of the local symbols that should be removed from the context on exit.
      switch stmt {
      case let decl as AllocStmt:
        localSymbols.append(decl.symbol)

        // If the allocation is performed on the stack, then we *must* collect the cell capability
        // at the end of the lexical scope.
        if decl.segment == .stack {
          if let ty = typingContext[decl.symbol]?.bareType {
            stackSymbols.append((ty as! LocType).location)
          }
        }

      case let decl as NamedDecl:
        localSymbols.append(decl.symbol)

      default:
        break
      }
    }

    // Remove the local symbols from the context.
    for sym in localSymbols {
      typingContext[sym] = nil
    }

    let endRange = node.range.map({ range in range.upperBound ..< range.upperBound })
    for sym in stackSymbols {
      if typingContext[sym] == nil {
        TypeError
          .missingCapability(symbol: sym, type: anyType, range: endRange)
          .report(in: astContext)
      } else {
        typingContext[sym] = nil
      }
    }
  }

  public func typeCheck(_ node: CallStmt) throws {
    // Determine the type of the value callee.
    let funcTy: FuncType
    let quantifiedParams: [QuantifiedParam]

    switch try type(of: node.ident).bareType {
    case let ty as FuncType:
      funcTy = ty
      quantifiedParams = []

    case let ty as QuantifiedType where (ty.quantifier == .universal) && (ty.base is FuncType):
      // swiftlint:disable:next force_cast
      funcTy = ty.base as! FuncType
      quantifiedParams = ty.params

    case let t:
      throw TypeError.callToNonFunctionType(expr: node.ident, type: t)
    }

    var solver = TypeSolver(
      context: typingContext,
      constraints: [],
      quantifiedParams: quantifiedParams)

    // Pair each argument's type with the corresponding parameter's type to build the set of typing
    // constraints that's used to instantiate the function's signature.
    for (arg, param) in zip(node.args, funcTy.params) {
      do {
        let lhs = try type(of: arg)
        solver.constraints.append(TypeSolver.Constraint(lhs: .type(lhs), rhs: .type(param)))
      } catch let error as TypeError {
        hasErrors = true
        error.report(in: astContext)
      }
    }

    // Solve the typing constraints.
    guard let assumptions = solver.solve() else {
      let argTypes = node.args.map({ arg in try? type(of: arg) })
      throw TypeError.invalidCallArgTypes(funcIdent: node.ident, argTypes: argTypes)
    }

    // Consume the assumptions required by the function.
    for assumption in assumptions where assumption.key.isLocRef {
      assert(typingContext[assumption.key]! <= assumption.value)
      typingContext[assumption.key] = nil
    }

    // Produce the assumptions generated by the function.
    let output = funcTy.output.substituting(solver.substitutions)
    if let (tau, eta) = output.opened {
      typingContext[node.symbol] = tau
      for assumption in eta {
        assert(typingContext[assumption.key] == nil)
        typingContext[assumption.key] = assumption.value
      }
    } else {
      typingContext[node.symbol] = output
    }
  }

  public func typeCheck(_ node: IfStmt) throws {
    // Visit the node's condition.
    node.cond.accept(self)

    // Check that the condition is a subtype of Bool.
    let tau = try type(of: node.cond)
    guard tau <= astContext.builtin.bool.qualified() else {
      throw TypeError.invalidTypeConversion(
        t1: tau,
        t2: astContext.builtin.bool.qualified(),
        range: node.cond.range)
    }

    // Type both branches of the statement individually.
    let context = typingContext
    node.thenBody.accept(self)
    let thenContext = typingContext

    typingContext = context
    node.elseBody?.accept(self)

    // Join the resulting contexts.
    typingContext = join(thenContext, typingContext)
  }

  public func typeCheck(_ node: LoadStmt) throws {
    // Determine the type of the l-value.
    let (baseExpr, path) = node.lvalue.storageRef
    let lvBaseType = try type(of: baseExpr)
    guard let loc = (lvBaseType.bareType as? LocType)?.location else {
      throw TypeError.invalidLValue(expr: baseExpr)
    }

    // Check that we have the capability to dereference the (base) location.
    guard let baseType = typingContext[loc] else {
      throw TypeError.missingCapability(symbol: loc, type: anyType, range: node.range)
    }

    // Dereference the storage's type.
    guard let storageType = baseType.dereference(path: path) else {
      throw TypeError.invalidMemberOffset(expr: node.lvalue)
    }

    typingContext[node.symbol] = storageType
  }

  public func typeCheck(_ node: ReturnStmt) throws {
    // Determine the type of the return value.
    let returnValueType = try type(of: node.value)

    // Check that the type of the return value matches the function's output type.
    let outputType: QualType
    let assumptions: TypingContext

    if let (tau, eta) = funcType.output.opened {
      outputType = tau
      assumptions = eta
    } else {
      outputType = funcType.output
      assumptions = [:]
    }

    guard returnValueType.isSubtype(of: outputType) else {
      throw TypeError.invalidTypeConversion(
        t1: returnValueType,
        t2: outputType,
        range: node.value.range)
    }

    // Verity that the the environment contains the assumptions described by the function's
    // return type.
    for assumption in assumptions {
      guard let tau = typingContext[assumption.key] else {
        hasErrors = true
        TypeError
          .missingCapability(symbol: assumption.key, type: assumption.value, range: node.range)
          .report(in: astContext)
        continue
      }

      guard tau <= assumption.value else {
        hasErrors = true
        TypeError
          .invalidAssumptionConversion(
            a1: (assumption.key, tau),
            a2: assumption,
            range: node.range)
          .report(in: astContext)
        continue
      }
    }
  }

  public func typeCheck(_ node: AllocStmt) {
    // Determine the new cell's memory layout.
    guard let storageType = node.sign.type else {
      // Skip the declaration if it's type is undefined. This can be done silently, as it should
      // only happen when the type realizer was not able to evaluate an appropriate type, which
      // would have resulted in a diagnostic.
      return
    }

    // Create a new location symbol.
    let sym = node.loc?.symbol ?? nextSymbol(isLocRef: true)

    // Associate the register with the freshly allocated cell.
    typingContext[node.symbol] = astContext
      .locType(location: sym)
      .qualified(by: .none)

    // Create a capability for the freshly allocated cell.
    typingContext[sym] = astContext
      .junkType(base: storageType.bareType)
      .qualified(by: storageType.quals)
  }

  public func typeCheck(_ node: FreeStmt) throws {
    // Determine the type of the expression.
    let exprTy = try type(of: node.expr)

    // Check that the expression refers to a pointer.
    guard let locTy = exprTy.bareType as? LocType else {
      throw TypeError.freeOnNonPointerType(expr: node.expr, type: exprTy.bareType)
    }

    // Check that we have the capability to delete the location.
    guard typingContext[locTy.location] != nil else {
      throw TypeError.missingCapability(symbol: locTy.location, type: anyType, range: node.range)
    }

    typingContext[locTy.location] = nil
  }

  public func typeCheck(_ node: StoreStmt) throws {
    // Determine the type of the r-value.
    let rvType = try type(of: node.rvalue)

    // Determine the type of the l-value.
    let (baseExpr, path) = node.lvalue.storageRef
    let lvBaseType = try type(of: baseExpr)
    guard let loc = (lvBaseType.bareType as? LocType)?.location else {
      throw TypeError.invalidLValue(expr: baseExpr)
    }

    // Check that we have the capability to dereference the (base) location.
    guard let baseType = typingContext[loc] else {
      throw TypeError.missingCapability(symbol: loc, type: anyType, range: node.range)
    }

    // Check that the layout of the value to store is compatible with the storage's layout.
    guard let storageType = baseType.dereference(path: path) else {
      throw TypeError.invalidMemberOffset(expr: node.lvalue)
    }
    guard rvType.isSubtype(of: storageType) else {
      throw TypeError.invalidTypeConversion(t1: rvType, t2: storageType, range: node.rvalue.range)
    }

    typingContext[loc] = baseType.substituting(typeAt: path, with: rvType)
  }

  // MARK: Helper functions

  private var nextSymbolID = 0

  private func nextSymbol(isLocRef: Bool) -> Symbol {
    let symbol = Symbol(id: nextSymbolID, isLocRef: isLocRef)
    nextSymbolID += 1
    return symbol
  }

  /// Implements `Γ ⊢ e : τ`.
  private func type(of e: Expr) throws -> QualType {
    switch e {
    case is BoolLit:
      return astContext.builtin.bool.qualified()

    case is IntLit:
      return astContext.builtin.int32.qualified()

    case is VoidLit:
      return astContext.builtin.void.qualified()

    case let ident as IdentExpr:
      guard let decl = ident.referredDecl else {
        throw TypeError.undefinedExprType(expr: e)
      }

      if let funcDecl = decl as? FuncDecl {
        guard let type = funcDecl.type else {
          throw TypeError.undefinedExprType(expr: e)
        }
        return type
      } else {
        guard let type = typingContext[decl.symbol] else {
          throw TypeError.undefinedExprType(expr: e)
        }
        return type
      }

    case let member as MemberExpr:
      let bareType: BareType

      switch try type(of: member.base).bareType {
      case let junk as JunkType:
        bareType = junk.base
      case let t:
        bareType = t
      }

      guard let tupleType = bareType as? TupleType else {
        throw TypeError.memberAccessInScalarType(expr: e, type: bareType)
      }
      guard member.offset < tupleType.members.count else {
        throw TypeError.invalidMemberOffset(expr: e)
      }
      return tupleType.members[member.offset]

    default:
      throw TypeError.undefinedExprType(expr: e)
    }
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

}
