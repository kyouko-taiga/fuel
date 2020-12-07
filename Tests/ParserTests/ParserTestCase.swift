import XCTest

import AST
import Basic
import Lexer
import Parser

protocol ParserTestCase {

  var astContext: ASTContext! { get }

  var sourceManager: SourceManager! { get }

  func tokenize(_ input: String) -> Lexer

  func parse<T, U>(
    _ input: String,
    file: StaticString,
    line: UInt,
    with parseFunc: (inout Parser) throws -> U
  ) -> T?

}

extension ParserTestCase {

  func tokenize(_ input: String) -> Lexer {
    let source = sourceManager.load(string: input)
    return Lexer(source: source)
  }

  func parse<T, U>(
    _ input: String,
    file: StaticString = #filePath,
    line: UInt = #line,
    with parseFunc: (inout Parser) throws -> U
  ) -> T? {
    let tokens = tokenize(input)
    var parser = Parser(astContext: astContext, input: tokens)

    do {
      let node = try parseFunc(&parser)
      guard let refined = node as? T else {
        XCTFail("Expected '\(T.self)', found '\(U.self)'", file: file, line: line)
        return nil
      }
      return refined
    } catch {
      XCTFail("Unexpected thrown exception: \(error)", file: file, line: line)
      return nil
    }
  }

}
