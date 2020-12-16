import AST
import Basic
import Diagnostic
import Lexer

/// A recursive descent (a.k.a. top-down) parser that builds an AST from a sequence of tokens.
///
/// The implementation essentially corresponds to a LL(1) parser with some custom logic to remove
/// left recursion and avoid backtracking.
public struct Parser: StreamProcessor {

  /// Creates a new parser.
  ///
  /// - Parameters:
  ///   - astContext: The AST context in which the parser executes.
  ///   - input: A sequence of tokens. `input` is enumerated during initialization; therefore it
  ///     must be a finite sequence.
  public init<S>(astContext: ASTContext, input: S) where S: Sequence, S.Element == Token {
    self.astContext = astContext
    self.input = Array(input)
  }

  /// The AST context in the parser runs.
  public let astContext: ASTContext

  public var input: [Token]

  public var index = 0

  // MARK: Declarations

  /// Parses a top level declaration.
  public mutating func parseTopLevelDecl() -> FuncDecl? {
    while index < input.endIndex {
      do {
        return try parseFuncDecl()
      } catch {
        // Report the parse error as a diagnostic.
        switch error {
        case let err as ParseError:
          astContext.report(message: err.message)
            .set(location: err.range?.lowerBound)
            .add(range: err.range)
        default:
          astContext.report(message: error.localizedDescription)
        }

        // Attempt to recover at the start of the next top-level declaration.
        take(while: { $0.kind != .func_ })
      }
    }

    // The parser reached the end of its input.
    return nil
  }

  /// Parses a function declaration.
  public mutating func parseFuncDecl() throws -> FuncDecl {
    guard let lead = take(.func_) else {
      throw ParseError(message: "expected 'func'", range: peek()?.range)
    }
    guard let name = take(.name) else {
      throw ParseError(message: "expected function name", range: peek()?.range)
    }

    var params: [FuncParamDecl] = []
    if take(.leftParen) != nil {
      let endIndex = input[index...].firstIndex(where: { $0.kind == .rightParen })
        ?? input.endIndex
      params = try parseList(
        until: endIndex,
        with: { parser in try parser.parseFuncParamDecl() })

      guard take(.rightParen) != nil else {
        throw ParseError(message: "expected ')' delimiter", range: peek()?.range)
      }
    }

    guard take(.colon) != nil else {
      throw ParseError(message: "expected ':' delimiter", range: input.last?.range)
    }

    let sign = try parseTypeSign()

    let body: BraceStmt?
    if peek()?.kind == .leftBrace {
      body = try parseBraceStmt()
    } else {
      body = nil
    }

    let decl = FuncDecl(
      name: String(name.value),
      params: params,
      sign: sign,
      body: body)
    decl.range = lead.range.lowerBound ..< (body?.range!.upperBound ?? sign.range!.upperBound)
    return decl
  }

  /// Parses the declaration of a function parameter.
  public mutating func parseFuncParamDecl() throws -> FuncParamDecl {
    guard let name = take(.name) else {
      throw ParseError(message: "expected parameter name", range: peek()?.range)
    }

    let decl = FuncParamDecl(name: String(name.value))
    decl.range = name.range
    return decl
  }

  /// Parses the declaration of a quantified parameter.
  public mutating func parseQuantParamDecl() throws -> QuantifiedParamDecl {
    guard let name = take(.name) else {
      throw ParseError(message: "expected parameter name", range: peek()?.range)
    }

    let decl = QuantifiedParamDecl(name: String(name.value))
    decl.range = name.range
    return decl
  }

  // MARK: Statements

  /// Parses a statement.
  public mutating func parseStmt() throws -> Stmt {
    switch peek()?.kind {
    case .name:
      let name = take(.name)!
      guard take(.equal) != nil else {
        throw ParseError(message: "expected '='", range: peek()?.range)
      }

      return try parseStmtTail(name: name)

    case .free:
      let lead = take(.free)!

      let expr = try parseExpr()
      guard let lvalue = expr as? LValueExpr else {
        throw ParseError(
          message: "target of free statement must be an l-value",
          range: expr.range)
      }

      let stmt = FreeStmt(lvalue: lvalue)
      stmt.range = lead.range.lowerBound ..< lvalue.range!.upperBound
      return stmt

    case .store:
      let lead = take(.store)!
      let rvalue = try parseExpr()

      guard take(.comma) != nil else {
        throw ParseError(message: "expected ',' separator", range: peek()?.range)
      }

      let expr = try parseExpr()
      guard let lvalue = expr as? LValueExpr else {
        throw ParseError(
          message: "target of store statement must be an l-value",
          range: expr.range)
      }

      let stmt = StoreStmt(rvalue: rvalue, lvalue: lvalue)
      stmt.range = lead.range.lowerBound ..< expr.range!.upperBound
      return stmt

    case .return_:
      let lead = take(.return_)!
      let value = try parseExpr()
      let stmt = ReturnStmt(value: value)
      stmt.range = lead.range.lowerBound ..< value.range!.upperBound
      return stmt

    case .if_:
      return try parseIfStmt()

    case .leftBrace:
      return try parseBraceStmt()

    default:
      throw ParseError(message: "expected statement", range: peek()?.range)
    }
  }

  /// Parses the tail of a value-binding statement
  public mutating func parseStmtTail(name: Token) throws -> Stmt {
    switch peek()?.kind {
    case .salloc, .halloc:
      let segment = take()!.kind == .salloc
        ? MemorySegment.stack
        : MemorySegment.heap

      let sign = try parseTypeSign()
      var upperBound = sign.range!.upperBound

      let loc: LocDecl?
      if take(.at) != nil {
        guard let tok = take(.name) else {
          throw ParseError(message: "expected location identifier", range: peek()?.range)
        }
        loc = LocDecl(name: String(tok.value))
        loc!.range = tok.range
        upperBound = tok.range.upperBound
      } else {
        loc = nil
      }

      let stmt = AllocStmt(name: String(name.value), segment: segment, sign: sign, loc: loc)
      stmt.range = name.range.lowerBound ..< upperBound
      return stmt

    case .load:
      take(.load)

      let expr = try parseExpr()
      guard let lvalue = expr as? LValueExpr else {
        throw ParseError(
          message: "argument of load statement must be an l-value",
          range: expr.range)
      }

      let stmt = LoadStmt(name: String(name.value), lvalue: lvalue)
      stmt.range = name.range.lowerBound ..< expr.range!.upperBound
      return stmt

    case .call:
      take(.call)

      let callee = try parseIdentExpr()

      var args: [Expr] = []
      if take(.comma) != nil {
        let endIndex = input[index...]
          .firstIndex(where: { $0.isFollowedByNewline })
          .map(input.index(after:))
        args = try parseList(
          until: endIndex ?? input.endIndex,
          with: { parser in try parser.parseExpr() })
      }

      let stmt = CallStmt(name: String(name.value), ident: callee, args: args)
      let ub = args.last?.range!.upperBound ?? callee.range!.upperBound
      stmt.range = name.range.lowerBound ..< ub
      return stmt

    default:
      throw ParseError(message: "expected value-binding statement keyword", range: peek()?.range)
    }
  }

  /// Parses a conditional statement.
  public mutating func parseIfStmt() throws -> IfStmt {
    guard let lead = take(.if_) else {
      throw ParseError(message: "expected 'if'", range: peek()?.range)
    }

    let cond = try parseExpr()
    let thenBody = try parseBraceStmt()

    let elseBody: BraceStmt?
    if take(.else_) != nil {
      elseBody = try parseBraceStmt()
    } else {
      elseBody = nil
    }

    let stmt = IfStmt(cond: cond, thenBody: thenBody, elseBody: elseBody)
    let ub = elseBody?.range!.upperBound ?? thenBody.range!.upperBound
    stmt.range = lead.range.lowerBound ..< ub
    return stmt
  }

  /// Parses a brace statement.
  public mutating func parseBraceStmt() throws -> BraceStmt {
    guard let lead = take(.leftBrace) else {
      throw ParseError(message: "expected '{' delimiter", range: peek()?.range)
    }

    var stmts: [Stmt] = []
    var trail = take(.rightBrace)
    while trail == nil {
      stmts.append(try parseStmt())
      trail = take(.rightBrace)
    }

    let stmt = BraceStmt(stmts: stmts)
    stmt.range = lead.range.lowerBound ..< trail!.range.upperBound
    return stmt
  }

  // MARK: Expressions

  /// Parses an expression.
  public mutating func parseExpr() throws -> Expr {
    var base: Expr
    switch peek()?.kind {
    case .name:
      base = try parseIdentExpr()

    case .void:
      base = try parseVoidLit()

    case .true_, .false_:
      base = try parseBoolLit()

    case .integer:
      base = try parseIntLit()

    default:
      throw ParseError(message: "expected expression", range: peek()?.range)
    }

    while take(.dot) != nil {
      guard let offset = take(.integer) else {
        throw ParseError(message: "expected offset", range: peek()?.range)
      }

      let expr = MemberExpr(base: base, offset: Int(offset.value)!)
      expr.range = base.range!.lowerBound ..< offset.range.upperBound
      base = expr
    }

    return base
  }

  /// Parses an identifier.
  public mutating func parseIdentExpr() throws -> IdentExpr {
    guard let name = take(.name) else {
      throw ParseError(message: "expected value identifier", range: peek()?.range)
    }

    let expr = IdentExpr(name: String(name.value))
    expr.range = name.range
    return expr
  }

  /// Parses a void literal.
  public mutating func parseVoidLit() throws -> VoidLit {
    guard let lead = take(.void) else {
      throw ParseError(message: "expected 'void' literal", range: peek()?.range)
    }

    let expr = VoidLit()
    expr.range = lead.range
    return expr
  }

  /// Parses a Boolean literal.
  public mutating func parseBoolLit() throws -> BoolLit {
    guard let lead = (take(.true_) ?? take(.false_)) else {
      throw ParseError(message: "expected Boolean literal", range: peek()?.range)
    }

    let expr = BoolLit(value: lead.value == "true")
    expr.range = lead.range
    return expr
  }

  /// Parses an integer literal.
  public mutating func parseIntLit() throws -> IntLit {
    guard let lead = take(.integer) else {
      throw ParseError(message: "expected integer literal", range: peek()?.range)
    }
    guard let value = Int(lead.value) else {
      throw ParseError(message: "invalid integer literal '\(lead.value)'", range: lead.range)
    }

    let expr = IntLit(value: value)
    expr.range = lead.range
    return expr
  }

  // MARK: Type Signatures

  /// Parses a type signature.
  public mutating func parseTypeSign() throws -> TypeSign {
    // Save the current location to build the signature's range if it starts with a qualifier.
    let lowerBound = peek()?.range.lowerBound

    // Parse a list of type qualifiers.
    var quals: [TypeQual] = []
    while let token = take(.qualifier) {
      guard let qual = TypeQual(token: token) else {
        throw ParseError(message: "invalid type qualifier '\(token.value)'", range: token.range)
      }
      quals.append(qual)
    }

    // Parse the bare type signature.
    let base = try parseBareTypeSign()
    if !quals.isEmpty {
      let sign = QualSign(base: base, qualifiers: quals)
      sign.range = lowerBound! ..< base.range!.upperBound
      return sign
    } else {
      return base
    }
  }

  /// Parses an unqualified type signature.
  public mutating func parseBareTypeSign() throws -> TypeSign {
    let base: TypeSign
    switch peek()?.kind {
    case .leftParen:
      let lead = peek()!
      let params = try parseParenthesizedSignList()

      if take(.arrow) != nil {
        let output = try parseTypeSign()
        let sign = FuncSign(params: params, output: output)
        sign.range = lead.range.lowerBound ..< output.range!.upperBound
        base = sign
      } else if params.count == 1 {
        base = params[0]
      } else {
        throw ParseError(message: "expected '->' separator", range: peek()?.range)
      }

    case .universal, .existential:
      base = try parseQuantifiedSign()

    case .name:
      base = try parseIdentSign()

    case .exclamation:
      base = try parseLocSign()

    case .leftBrace:
      base = try parseTupleSign()

    default:
      throw ParseError(message: "expected type signature", range: peek()?.range)
    }

    // Parse a list of assumptions.
    var assumps: [AssumptionSign] = []
    while take(.plus) != nil {
      assumps.append(try parseAssumpSign())
    }

    if !assumps.isEmpty {
      let bundle = BundledSign(base: base, assumptions: assumps)
      bundle.range = base.range!.lowerBound ..< assumps.last!.range!.upperBound
      return bundle
    } else {
      return base
    }
  }

  /// Parses parenthesized a list of type signatures
  public mutating func parseParenthesizedSignList() throws -> [TypeSign] {
    guard take(.leftParen) != nil else {
      throw ParseError(message: "expected '(' delimiter", range: peek()?.range)
    }

    let endIndex = indexOfMatchingDelimiter(openKind: .leftParen, closeKind: .rightParen)
    let signs = try parseList(
      until: endIndex,
      with: { parser in try parser.parseTypeSign() })

    guard take(.rightParen) != nil else {
      throw ParseError(message: "expected ')' delimiter", range: peek()?.range)
    }

    return signs
  }

  /// Parses a quantified type signature.
  public mutating func parseQuantifiedSign() throws -> QuantifiedSign {
    guard let lead = take(.universal) ?? take(.existential) else {
      throw ParseError(message: "expected quantifier", range: peek()?.range)
    }

    let endIndex = input[index...].firstIndex(where: { $0.kind == .dot })
      ?? input.endIndex
    let params = try parseList(
      until: endIndex,
      with: { parser in try parser.parseQuantParamDecl() })

    guard take(.dot) != nil else {
      throw ParseError(message: "expected '.' separator", range: peek()?.range)
    }

    let base = try parseBareTypeSign()
    let quantifier = lead.kind == .universal
      ? Quantifier.universal
      : Quantifier.existential

    let sign = QuantifiedSign(quantifier: quantifier, params: params, base: base)
    sign.range = lead.range.lowerBound ..< base.range!.upperBound
    return sign
  }

  /// Parses a type identifier.
  public mutating func parseIdentSign() throws -> IdentSign {
    guard let name = take(.name) else {
      throw ParseError(message: "expected type identifier", range: peek()?.range)
    }

    let sign = IdentSign(name: String(name.value))
    sign.range = name.range
    return sign
  }

  /// Parses a location signature.
  public mutating func parseLocSign() throws -> LocSign {
    guard let lead = take(.exclamation) else {
      throw ParseError(message: "expected '!'", range: peek()?.range)
    }
    guard let ident = try? parseIdentExpr() else {
      throw ParseError(message: "expected location identifier folowing '!'", range: peek()?.range)
    }

    let sign = LocSign(location: ident)
    sign.range = lead.range.lowerBound ..< ident.range!.upperBound
    return sign
  }

  /// Parses a tuple signature.
  public mutating func parseTupleSign() throws -> TupleSign {
    guard let lead = take(.leftBrace) else {
      throw ParseError(message: "expected '{' delimiter", range: peek()?.range)
    }

    let endIndex = indexOfMatchingDelimiter(openKind: .leftBrace, closeKind: .rightBrace)
    let members = try parseList(
      until: endIndex,
      with: { parser in try parser.parseTypeSign() })

    guard let trail = take(.rightBrace) else {
      throw ParseError(message: "expected '}' delimiter", range: peek()?.range)
    }

    let sign = TupleSign(members: members)
    sign.range = lead.range.lowerBound ..< trail.range.upperBound
    return sign
  }

  /// Parses an assumption.
  public mutating func parseAssumpSign() throws -> AssumptionSign {
    guard let lead = take(.leftBracket) else {
      throw ParseError(message: "expected '[' delimiter", range: peek()?.range)
    }

    let ident = try parseIdentExpr()

    guard take(.colon) != nil else {
      throw ParseError(message: "expected ':' separator", range: peek()?.range)
    }

    let sign = try parseTypeSign()

    guard let trail = take(.rightBracket) else {
      throw ParseError(message: "expected ']' delimiter", range: peek()?.range)
    }

    let assump = AssumptionSign(ident: ident, sign: sign)
    assump.range = lead.range.lowerBound ..< trail.range.upperBound
    return assump
  }

  // MARK: Helpers

  /// Parses a comma-separated list of constructions.
  private mutating func parseList<T>(
    until endIndex: Int,
    with parseFunc: (inout Parser) throws -> T
  ) throws -> [T] {
    var elements: [T] = []

    while index < endIndex {
      elements.append(try parseFunc(&self))
      if index >= endIndex {
        break
      } else if take(.comma) != nil {
        continue
      } else {
        throw ParseError(message: "expected ',' separator", range: peek()?.range)
      }
    }

    return elements
  }

  /// Consumes the next element from the stream if it has the given kind.
  ///
  /// - Parameter kind: The kind of tokens to consume.
  @discardableResult
  private mutating func take(_ kind: Token.Kind) -> Token? {
    guard index < input.endIndex else {
      return nil
    }

    let element = input[index]
    guard element.kind == kind else {
      return nil
    }

    index = input.index(after: index)
    return element
  }

  /// Determines the index of the specified closing delimiter, ignoring nested pairs of delimiters.
  ///
  /// This helper method can be used to determine how far the parser should go to read a list of
  /// constructions. For instance, assuming the current index is `1` and the parser's input is
  /// equivalent to `((a), b)`, then the method returns the index 7.
  ///
  /// - Parameters:
  ///   - openKind: The kind of tokens that correspond to opening delimiters.
  ///   - closeKind: The kind of tokens that correspond to closing delimiters.
  private func indexOfMatchingDelimiter(openKind: Token.Kind, closeKind: Token.Kind) -> Int {
    var endIndex = index
    var openCount = 1

    while endIndex < input.endIndex {
      if input[endIndex].kind == closeKind {
        openCount -= 1
        if openCount == 0 {
          break
        }
      } else if input[endIndex].kind == openKind {
        openCount += 1
      }

      endIndex = input.index(after: endIndex)
    }

    return endIndex
  }

}

struct ParseError: Error {

  let message: String

  let range: SourceRange?

}
