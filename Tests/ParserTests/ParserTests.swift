import XCTest

import AST
import Basic

class ParserTests: XCTestCase, ParserTestCase {

  var astContext: ASTContext!

  var sourceManager: SourceManager!

  override func setUp() {
    astContext = ASTContext()
    sourceManager = SourceManager()
  }

  override func tearDown() {
    astContext = nil
    sourceManager = nil
  }

  // MARK: Declarations

  func testExtParseFuncDecl() {
    if let decl: FuncDecl = parse("func f : () -> C", with: { try $0.parseFuncDecl() }) {
      XCTAssertEqual(decl.name, "f")
      XCTAssertEqual(decl.params.count, 0)
    }

    if let decl: FuncDecl = parse("func f() : () -> C", with: { try $0.parseFuncDecl() }) {
      XCTAssertEqual(decl.name, "f")
      XCTAssertEqual(decl.params.count, 0)
    }

    if let decl: FuncDecl = parse("func f(x) : (A) -> C", with: { try $0.parseFuncDecl() }) {
      XCTAssertEqual(decl.name, "f")
      XCTAssertEqual(decl.params.count, 1)
      XCTAssertEqual(decl.params.first?.name, "x")
    }

    let input = "func f(x, y) : (A, B) -> C"
    if let decl: FuncDecl = parse(input, with: { try $0.parseFuncDecl() }) {
      XCTAssertEqual(decl.name, "f")
      XCTAssertEqual(decl.params.count, 2)
      if decl.params.count == 2 {
        XCTAssertEqual(decl.params[0].name, "x")
        XCTAssertEqual(decl.params[1].name, "y")
      }
    }
  }

  func testParseFuncDecl() throws {
    let input = """
    func id(x) : (A) -> A {
      return x
    }
    """
    if let decl: FuncDecl = parse(input, with: { try $0.parseFuncDecl() }) {
      let body = try XCTUnwrap(decl.body)
      XCTAssertEqual(body.stmts.count, 1)
    }
  }

  // MARK: Statements

  func testParseFreeStmt() {
    let _: FreeStmt? = parse("free foo", with: { try $0.parseStmt() })
  }

  func testParseStoreStmt() {
    let _: StoreStmt? = parse("store 1337, foo", with: { try $0.parseStmt() })
    let _: StoreStmt? = parse("store 1337, foo.0", with: { try $0.parseStmt() })
  }

  func testParseReturnStmt() {
    let _: ReturnStmt? = parse("return 1337", with: { try $0.parseStmt() })
  }

  func testParseScopeAllocStmt() throws {
    if let stmt: ScopeAllocStmt = parse("foo = salloc T", with: { try $0.parseStmt() }) {
      XCTAssertEqual(stmt.name, "foo")
      XCTAssert(stmt.sign is IdentSign)
      XCTAssertNil(stmt.loc)
    }

    if let stmt: ScopeAllocStmt = parse("foo = salloc T at a", with: { try $0.parseStmt() }) {
      XCTAssertEqual(stmt.name, "foo")
      XCTAssert(stmt.sign is IdentSign)
      let loc = try XCTUnwrap(stmt.loc)
      XCTAssertEqual(loc.name, "a")
    }
  }

  func testParseLoadStmt() {
    if let stmt: LoadStmt = parse("foo = load bar", with: { try $0.parseStmt() }) {
      XCTAssertEqual(stmt.name, "foo")
    }

    if let stmt: LoadStmt = parse("foo = load bar.1", with: { try $0.parseStmt() }) {
      XCTAssertEqual(stmt.name, "foo")
    }
  }

  func testParseCallStmt() {
    // A call statement without any argument.
    if let stmt: CallStmt = parse("foo = call bar", with: { try $0.parseStmt() }) {
      XCTAssertEqual(stmt.name, "foo")
      XCTAssertEqual(stmt.args.count, 0)
    }

    // A call statement with a single argument.
    if let stmt: CallStmt = parse("foo = call bar, ham", with: { try $0.parseStmt() }) {
      XCTAssertEqual(stmt.name, "foo")
      XCTAssertEqual(stmt.args.count, 1)
    }

    // A call statement with multiple arguments.
    if let stmt: CallStmt = parse("foo = call bar, ham, 0", with: { try $0.parseStmt() }) {
      XCTAssertEqual(stmt.name, "foo")
      XCTAssertEqual(stmt.args.count, 2)
    }
  }

  func testParseIfStmt() {
    // A conditional statement without an "else" clause.
    if let stmt: IfStmt = parse("if foo {}", with: { try $0.parseStmt() }) {
      XCTAssertNil(stmt.elseBody)
    }

    // A conditional statement with an "else" clause.
    if let stmt: IfStmt = parse("if foo {} else {}", with: { try $0.parseStmt() }) {
      XCTAssertNotNil(stmt.elseBody)
    }
  }

  func testParseBraceStmt() {
    if let brace: BraceStmt = parse("{}", with: { try $0.parseStmt() }) {
      XCTAssertEqual(brace.stmts.count, 0)
    }

    let input1 = """
    {
      foo = salloc A
    }
    """
    if let brace: BraceStmt = parse(input1, with: { try $0.parseStmt() }) {
      XCTAssertEqual(brace.stmts.count, 1)
      XCTAssert(brace.stmts.first is ScopeAllocStmt)
    }

    let input2 = """
    {
      foo = salloc A
      {
        foo = salloc B
      }
    }
    """
    if let brace: BraceStmt = parse(input2, with: { try $0.parseStmt() }) {
      XCTAssertEqual(brace.stmts.count, 2)
      if brace.stmts.count == 2 {
        XCTAssert(brace.stmts[0] is ScopeAllocStmt)
        XCTAssert(brace.stmts[1] is BraceStmt)
      }
    }
  }

  // MARK: Expressions

  func testParseMemberExpr() {
    if let expr: MemberExpr = parse("foo.0", with: { try $0.parseExpr() }) {
      XCTAssert(expr.base is IdentExpr)
      XCTAssertEqual(expr.offset, 0)
    }

    if let expr: MemberExpr = parse("foo.0.1", with: { try $0.parseExpr() }) {
      XCTAssert(expr.base is MemberExpr)
      XCTAssertEqual(expr.offset, 1)
    }
  }

  func testParseIdentExpr() {
    if let expr: IdentExpr = parse("foo", with: { try $0.parseExpr() }) {
      XCTAssertEqual(expr.name, "foo")
    }
  }

  func testParseVoidLit() {
    let _: VoidLit? = parse("void", with: { try $0.parseExpr() })
  }

  func testParseTrueLit() {
    if let expr: BoolLit = parse("true", with: { try $0.parseExpr() }) {
      XCTAssertTrue(expr.value)
    }
  }

  func testParseFalseLit() {
    if let expr: BoolLit = parse("false", with: { try $0.parseExpr() }) {
      XCTAssertFalse(expr.value)
    }
  }

  // MARK: Type Signatures

  func testParseQualSign() throws {
    if let sign: QualSign = parse("@const T", with: { try $0.parseTypeSign() }) {
      XCTAssert(sign.base is IdentSign)
      XCTAssertEqual(sign.qualifiers.count, 1)
      XCTAssertEqual(sign.qualifiers.first, .const)
    }

    if let sign: QualSign = parse("@const @unscoped T", with: { try $0.parseTypeSign() }) {
      XCTAssert(sign.base is IdentSign)
      XCTAssertEqual(sign.qualifiers.count, 2)
      if sign.qualifiers.count == 2 {
        XCTAssertEqual(sign.qualifiers[0], .const)
        XCTAssertEqual(sign.qualifiers[1], .unscoped)
      }
    }

    let _: QualSign? = parse("@unscoped (T)", with: { try $0.parseTypeSign() })
    let _: QualSign? = parse("(@unscoped T)", with: { try $0.parseTypeSign() })
  }

  func testParseBundledSign() throws {
    if let sign: BundledSign = parse("!a + [a: T]", with: { try $0.parseTypeSign() }) {
      XCTAssert(sign.base is LocSign)
      XCTAssertEqual(sign.assumptions.count, 1)
    }

    if let sign: BundledSign = parse("!a + [a: T] + [b: U]", with: { try $0.parseTypeSign() }) {
      XCTAssert(sign.base is LocSign)
      XCTAssertEqual(sign.assumptions.count, 2)
    }

    let _: BundledSign? = parse("(!a) + [a: T]", with: { try $0.parseTypeSign() })
  }

  func testParseQuantifiedSign() throws {
    // A universally quantified signature without any parameter.
    if let sign: QuantifiedSign = parse(#"\A . T"#, with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.quantifier, .universal)
      XCTAssertEqual(sign.params.count, 0)
    }

    // An existentiall quantified signature without any parameter.
    if let sign: QuantifiedSign = parse(#"\E . T"#, with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.quantifier, .existential)
      XCTAssertEqual(sign.params.count, 0)
    }

    // A universally quantified signature with a single parameter.
    if let sign: QuantifiedSign = parse(#"\A a . T"#, with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.quantifier, .universal)
      XCTAssertEqual(sign.params.count, 1)
      XCTAssertEqual(sign.params.first?.name, "a")
    }

    // An existentially quantified signature with a single parameter.
    if let sign: QuantifiedSign = parse(#"\E a . T"#, with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.quantifier, .existential)
      XCTAssertEqual(sign.params.count, 1)
      XCTAssertEqual(sign.params.first?.name, "a")
    }

    // A universally quantified function signature with multiple parameters.
    let input = #"\A a, b . (!a + [a: Int], !b + [b: Int]) -> Void + [a: Int] + [b: Int]"#
    if let sign: QuantifiedSign = parse(input, with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.quantifier, .universal)
      XCTAssertEqual(sign.params.count, 2)
      if sign.params.count == 2 {
        XCTAssertEqual(sign.params[0].name, "a")
        XCTAssertEqual(sign.params[1].name, "b")
      }
      XCTAssert(sign.base is FuncSign)
    }

    let _: QuantifiedSign? = parse(#"\A a . (T)"#, with: { try $0.parseTypeSign() })
    let _: QuantifiedSign? = parse(#"(\A a . T)"#, with: { try $0.parseTypeSign() })
  }

  func testParseFuncSign() {
    // A function signature without any parameter.
    if let sign: FuncSign = parse("() -> C", with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.params.count, 0)
      XCTAssertEqual((sign.output as? IdentSign)?.name, "C")
    }

    // A function signature with a single parameter.
    if let sign: FuncSign = parse("(A) -> C", with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.params.count, 1)
      XCTAssertEqual((sign.params.first as? IdentSign)?.name, "A")
      XCTAssertEqual((sign.output as? IdentSign)?.name, "C")
    }

    // A function signature with multiple parameters.
    if let sign: FuncSign = parse("(A, B) -> C", with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.params.count, 2)
      if sign.params.count == 2 {
        XCTAssertEqual((sign.params[0] as? IdentSign)?.name, "A")
        XCTAssertEqual((sign.params[1] as? IdentSign)?.name, "B")
      }
      XCTAssertEqual((sign.output as? IdentSign)?.name, "C")
    }

    // A function signature whose output type is bundled.
    if let sign: FuncSign = parse("(A, B) -> C + [x: T]", with: { try $0.parseTypeSign() }) {
      XCTAssert(sign.output is BundledSign)
    }

    let _: FuncSign? = parse("((A)) -> C"   , with: { try $0.parseTypeSign() })
    let _: FuncSign? = parse("((A), B) -> C", with: { try $0.parseTypeSign() })
    let _: FuncSign? = parse("((A, B) -> C)", with: { try $0.parseTypeSign() })
  }

  func testParseTupleSign() {
    // A tuple signature without any member.
    if let sign: TupleSign = parse("{}", with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.members.count, 0)
    }

    // A tuple signature with a single member.
    if let sign: TupleSign = parse("{ A }", with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.members.count, 1)
      XCTAssertEqual((sign.members.first as? IdentSign)?.name, "A")
    }

    // A tuple signature with multiple members.
    if let sign: TupleSign = parse("{ A, B }", with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.members.count, 2)
      if sign.members.count == 2 {
        XCTAssertEqual((sign.members[0] as? IdentSign)?.name, "A")
        XCTAssertEqual((sign.members[1] as? IdentSign)?.name, "B")
      }
    }

    // A tuple signature with a nested tuple member.
    if let sign: TupleSign = parse("{ { A, B }, C }", with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.members.count, 2)
      XCTAssert(sign.members.first is TupleSign)
    }

    let _: TupleSign? = parse("{ (A), B }", with: { try $0.parseTypeSign() })
    let _: TupleSign? = parse("({ A, B })", with: { try $0.parseTypeSign() })
  }

  func testParseIdentSign() throws {
    if let sign: IdentSign = parse("T", with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.name, "T")
    }

    let _: IdentSign? = parse("(T)"  , with: { try $0.parseTypeSign() })
    let _: IdentSign? = parse("((T))", with: { try $0.parseTypeSign() })
  }

  func testParseLocSign() throws {
    if let sign: LocSign = parse("!a", with: { try $0.parseTypeSign() }) {
      XCTAssertEqual(sign.location.name, "a")
    }

    let _: LocSign? = parse("(!a)", with: { try $0.parseTypeSign() })
  }

}
