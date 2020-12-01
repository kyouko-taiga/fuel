import Diesel

public enum FuelParser {

  public static func initialize() {
    stmt.define(
         varDecl
      || free   .map({ $0 as Stmt })
      || store  .map({ $0 as Stmt })
      || return_.map({ $0 as Stmt })
      || if_    .map({ $0 as Stmt }))

    typeSign.define(
         funcSign.map({ $0 as TypeSign })
      || universalSign
      || atomSign)

    atomSign.define(
         identSign    .map({ $0 as TypeSign })
      || locationSign .map({ $0 as TypeSign })
      || pointerSign  .map({ $0 as TypeSign })
      || tupleSign    .map({ $0 as TypeSign })
      || typeSign.parenthesized)
  }

  public static let decls = funcDecl.surrounded(by: newlines).many

  static let funcDecl = (funcHead ++ block.surrounded(by: newlines).optional)
    .map({ (decl, body) -> FuncDecl in
      if let b = body {
        decl.body = b
        decl.range = decl.range!.lowerBound ..< b.range!.upperBound
      }
      return decl
    })

  static let funcHead = (
    (t(.func_)
      ++ t(.name)
      ++ funcParamDeclList.optional.parenthesized
      ++ (t(.colon) >+ typeSign)))
    .map({ (tree) -> FuncDecl in
      let (((lead, name), params), sign) = tree

      let decl = FuncDecl(
        name: String(name.value),
        params: params ?? [],
        sign: sign,
        body: nil)

      decl.range = lead.range.lowerBound ..< sign.range!.upperBound
      return decl
    })

  static let funcParamDeclList = (t(.name) ++ (t(.comma) >+ t(.name)).many)
    .map({ (head, tail) -> [FuncParamDecl] in
      var decls = [FuncParamDecl(name: String(head.value))]
      decls[0].range = head.range

      for token in tail {
        let decl = FuncParamDecl(name: String(token.value))
        decl.range = token.range
        decls.append(decl)
      }

      return decls
    })

  static let block = (
    t(.leftBrace)
      +> newlines
      ++ (stmtList +> newlines).optional
      ++ t(.rightBrace))
    .map({ (tree) -> Block in
      let ((lead, body), trail) = tree

      let block = Block(stmts: body ?? [])
      block.range = lead.range.lowerBound ..< trail.range.upperBound
      return block
    })

  static let stmtList = (stmt ++ (t(.newline)+ >+ stmt).many)
    .map({ head, tail in
      [head] + tail
    })

  static let stmt = ForwardParser<Stmt, ArraySlice<Token>>()

  static let varDecl = ((t(.name) +> t(.equal)) ++ stmtTail)
    .map({ (name, tail) -> Stmt in
      let lowerBound = name.range.lowerBound

      switch tail {
      case .salloc(sign: let sign):
        let stmt = ScopeAllocStmt(name: String(name.value), sign: sign)
        stmt.range = lowerBound ..< sign.range!.upperBound
        return stmt

      case .load(valueRef: let valueRef):
        let stmt = LoadStmt(name: String(name.value), valueRef: valueRef)
        stmt.range = lowerBound ..<  valueRef.range!.upperBound
        return stmt

      case .call(ident: let ident, args: let args):
        let stmt = CallStmt(name: String(name.value), ident: ident, args: args)
        let upperBound = args.last?.range!.upperBound ?? ident.range!.upperBound
        stmt.range = lowerBound ..< upperBound
        return stmt
      }
    })

  static let stmtTail = (sallocTail || loadTail || callTail)

  static let sallocTail = (t(.salloc) >+ typeSign)
    .map({ sign in
      StmtTail.salloc(sign: sign)
    })

  static let loadTail = (t(.load) >+ expr)
    .map({ valueRef in
      StmtTail.load(valueRef: valueRef)
    })

  static let callTail = ((t(.call) >+ ident) ++ (t(.comma) >+ argList).optional)
    .map({ ident, args in
      StmtTail.call(ident: ident, args: args ?? [])
    })

  static let argList = (expr ++ (t(.comma) >+ expr).many)
    .map({ head, tail in
      [head] + tail
    })

  static let free = (t(.free) ++ ident)
    .map({ (lead, ident) -> FreeStmt in
      let stmt = FreeStmt(ident: ident)
      stmt.range = lead.range.lowerBound ..< ident.range!.upperBound
      return stmt
    })

  static let store = ((t(.store) ++ expr) +> t(.comma) ++ ident)
    .map({ (tree) -> StoreStmt in
      let ((lead, value), ident) = tree

      let stmt = StoreStmt(value: value, ident: ident)
      stmt.range = lead.range.lowerBound ..< ident.range!.upperBound
      return stmt
    })

  static let return_ = (t(.return_) ++ expr)
    .map({ (lead, value) -> ReturnStmt in
      let stmt = ReturnStmt(value: value)
      stmt.range = lead.range.lowerBound ..< value.range!.upperBound
      return stmt
    })

  static let if_ = (t(.if_) ++ expr ++ (newlines >+ block) ++ (newlines >+ elseBody).optional)
    .map({ (tree) -> IfStmt in
      let (((lead, cond), then_), else_) = tree

      let stmt = IfStmt(cond: cond, thenBody: then_, elseBody: nil)
      stmt.range = lead.range.lowerBound ..< then_.range!.upperBound

      if let e = else_ {
        stmt.elseBody = e
        stmt.range = lead.range.lowerBound ..< e.range!.upperBound
      }

      return stmt
    })

  static let elseBody = (t(.else_) >+ newlines >+ block)

  static let expr = (atom ++ (t(.dot) >+ t(.integer)).many)
    .map({ (base, offsets) -> Expr in
      return offsets.reduce(base, { (base, offset) -> Expr in
        let e = MemberExpr(base: base, offset: Int(offset.value)!)
        e.range = e.range!.lowerBound ..< offset.range.upperBound
        return e as Expr
      })
    })

  static let atom =
       junkLit.map({ $0 as Expr })
    || voidLit.map({ $0 as Expr })
    || intLit .map({ $0 as Expr })
    || boolLit.map({ $0 as Expr })
    || ident  .map({ $0 as Expr })

  static let junkLit = t(.junk)
    .map({ (value) -> JunkLit in
      let lit = JunkLit()
      lit.range = value.range
      return lit
    })

  static let voidLit = t(.void)
    .map({ (value) -> VoidLit in
      let lit = VoidLit()
      lit.range = value.range
      return lit
    })

  static let boolLit = (t(.true_) || t(.false_))
    .map({ (value) -> BoolLit in
      let lit = BoolLit(value: value.value == "true")
      lit.range = value.range
      return lit
    })

  static let intLit = t(.integer)
    .map({ (integer) -> IntLit in
      let lit = IntLit(value: Int(integer.value)!)
      lit.range = integer.range
      return lit
    })

  static let ident = t(.name)
    .map({ (name) -> IdentExpr in
      let ident = IdentExpr(name: String(name.value))
      ident.range = name.range
      return ident
    })

  static let typeSignList = (typeSign ++ (t(.comma) >+ typeSign).many)
    .map({ head, tail in
      [head] + tail
    })

  static let typeSign = ForwardParser<TypeSign, ArraySlice<Token>>()

  static let atomSign = ForwardParser<TypeSign, ArraySlice<Token>>()

  static let universalSign = (
    t(.universal)
      ++ quantifiedParamDeclList
      ++ (t(.dot) >+ packedSign))
    .map({ (tree) -> TypeSign in
      let ((lead, params), base) = tree

      guard !params.isEmpty
        else { return base }

      let sign = UniversalSign(base: base, params: params)
      sign.range = lead.range.lowerBound ..< base.range!.upperBound
      return sign
    })

  static let funcSign = (
    t(.leftParen)
      ++ funcParamSignList.optional
      +> t(.rightParen)
      +> t(.arrow)
      ++ packedSign)
    .map({ (tree) -> FuncSign in
      let ((lead, params), output) = tree
      let sign = FuncSign(params: params ?? [], output: output)
      sign.range = lead.range.lowerBound ..< output.range!.upperBound
      return sign
    })

  static let funcParamSignList = (packedSign ++ (t(.comma) >+ packedSign).many)
    .map({ (head, tail) -> [TypeSign] in
      return [head] + tail
    })

  static let packedSign = (
    qualifierList.optional
      ++ atomSign
      ++ (t(.plus) >+ assumption).many)
    .map({ (tree) -> TypeSign in
      let ((qualifiers, base), assumptions) = tree
      guard !assumptions.isEmpty
        else { return base }

      var sign = base

      if !assumptions.isEmpty {
        sign = PackedSign(base: base, assumptions: assumptions)
        sign.range = base.range!.lowerBound ..< assumptions.last!.range!.upperBound
      }

      if let qualSet = qualifiers?.compactMap(TypeQual.init(token:)) {
        sign = QualSign(base: sign, qualifiers: qualSet)
        sign.range = qualifiers!.first!.range.lowerBound ..< sign.range!.upperBound
      }

      return sign
    })

  static let identSign = t(.name)
    .map({ (name) -> IdentSign in
      let sign = IdentSign(name: String(name.value))
      sign.range = name.range
      return sign
    })

  static let locationSign = (t(.exclamation) ++ ident)
    .map({ (lead, location) -> LocationSign in
      let sign = LocationSign(location: location)
      sign.range = lead.range.lowerBound ..< location.range!.upperBound
      return sign
    })

  static let pointerSign = (t(.and) ++ atomSign)
    .map({ (lead, sign) -> PointerSign in
      let sign = PointerSign(base: sign)
      sign.range = lead.range.lowerBound ..< sign.range!.upperBound
      return sign
    })

  static let tupleSign = (
    t(.leftBrace)
      ++ typeSignList.surrounded(by: newlines)
      ++ t(.rightBrace))
    .map({ (tree) -> TupleSign in
      let ((lead, members), trail) = tree

      let sign = TupleSign(members: members)
      sign.range = lead.range.lowerBound ..< trail.range.upperBound
      return sign
    })

  static let assumption = (t(.leftBracket) ++ (ident +> t(.colon)) ++ typeSign ++ t(.rightBracket))
    .map({ (tree) -> AssumptionSign in
      let (((lead, ident), sign), trail) = tree

      let assumption = AssumptionSign(ident: ident, sign: sign)
      assumption.range = lead.range.lowerBound ..< lead.range.upperBound
      return assumption
    })

  static let quantifiedParamDeclList =
    (quantifiedParamDecl ++ (t(.comma) >+ quantifiedParamDecl).many)
      .map({ (head, tail) -> [QuantifiedParamDecl] in
        return [head] + tail
      })

  static let quantifiedParamDecl = t(.name)
    .map({ (name) -> QuantifiedParamDecl in
      let decl = QuantifiedParamDecl(name: String(name.value))
      decl.range = name.range
      return decl
    })

  static let qualifierList = qualifier.oneOrMany

  static let qualifier = t(.qualifier)

  static let newlines = t(.newline).many

}

enum StmtTail {

  case salloc(sign: TypeSign)

  case load(valueRef: Expr)

  case call(ident: IdentExpr, args: [Expr])

}

extension Parser where Stream == ArraySlice<Token> {

  var parenthesized: AnyParser<Element, Stream> {
    return AnyParser(t(.leftParen) >+ self.surrounded(by: t(.newline).many) +> t(.rightParen))
  }

}

extension TypeQual {

  init?(token: Token) {
    switch token.value {
    case "@unscoped": self = .unscoped
    case "@copyable": self = .copyable
    default         : return nil
    }
  }

}

func t(_ kind: Token.Kind) -> ElementParser<ArraySlice<Token>> {
  return ElementParser(predicate: { $0.kind == kind }, onFailure: { _ in nil })
}
