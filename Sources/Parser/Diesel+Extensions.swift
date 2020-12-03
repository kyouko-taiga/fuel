import Diesel
import Lexer

infix operator ++ : AdditionPrecedence

infix operator >+ : AdditionPrecedence

infix operator +> : AdditionPrecedence

postfix operator +

func ++ <P, Q>(lhs: P, rhs: Q) -> CombineParser<P, Q, (P.Element, Q.Element)>
where P: Diesel.Parser, Q: Diesel.Parser
{
  return lhs.then(rhs)
}

func >+ <P, Q>(lhs: P, rhs: Q) -> CombineParser<P, Q, Q.Element>
where P: Diesel.Parser, Q: Diesel.Parser
{
  return lhs.then(rhs, combine: { _, rhs in rhs })
}

func +> <P, Q>(lhs: P, rhs: Q) -> CombineParser<P, Q, P.Element>
where P: Diesel.Parser, Q: Diesel.Parser
{
  return lhs.then(rhs, combine: { lhs, _ in lhs })
}

func || <P, Q>(lhs: P, rhs: Q) -> EitherParser<P, Q>
where P: Diesel.Parser, Q: Diesel.Parser
{
  return lhs.or(rhs)
}

extension Diesel.Parser {

  static postfix func + (parser: Self) -> CombineParser<Self, ManyParser<Self>, [Self.Element]> {
    return parser.oneOrMany
  }

}

extension Diesel.Parser where Stream == ArraySlice<Token> {

  var parenthesized: AnyParser<Element, Stream> {
    return AnyParser(t(.leftParen) >+ self.surrounded(by: t(.newline).many) +> t(.rightParen))
  }

}
