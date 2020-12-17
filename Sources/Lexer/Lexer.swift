// swiftlint:disable comma cyclomatic_complexity
import Basic

/// An iterator that tokenizes the contents of a source file.
public struct Lexer: IteratorProtocol, Sequence, StreamProcessor {

  /// Creates a new lexer for the given source file.
  ///
  /// - Parameter input: A source file.
  public init(input: SourceFile) {
    self.input = input
    self.index = input.startIndex
  }

  /// The contents of the file being tokenized.
  public let input: SourceFile

  /// The index from which the file is being tokenized.
  public var index: SourceFile.Index

  /// A boolean value that indicates whether the source file has been completed processed.
  private var depleted = false

  public mutating func next() -> Token? {
    while index < input.endIndex {
      // Skip all leading whitespace characters.
      take(while: { $0.isWhitespace })

      // Skip the remainder of the line if we recognized a comment.
      if peek(n: 2) == "//" {
        take(while: { !$0.isNewline })
        continue
      }

      // The stream now starts with a
      break
    }

    guard let ch = peek() else { return nil }
    assert(!ch.isWhitespace)
    let start = index

    // Lex identifiers and keywords.
    if ch.isLetter || ch == "_" {
      let identifier = take(while: { $0.isLetter || $0.isDigit || $0 == "_" })
      let value = input[start ..< index]

      switch identifier {
      case "return":
        return Token(kind: .return_ , value: value)
      case "func":
        return Token(kind: .func_   , value: value)
      case "salloc":
        return Token(kind: .salloc  , value: value)
      case "halloc":
        return Token(kind: .halloc  , value: value)
      case "at":
        return Token(kind: .at      , value: value)
      case "call":
        return Token(kind: .call    , value: value)
      case "insert":
        return Token(kind: .insert  , value: value)
      case "extract":
        return Token(kind: .extract , value: value)
      case "free":
        return Token(kind: .free    , value: value)
      case "store":
        return Token(kind: .store   , value: value)
      case "load":
        return Token(kind: .load    , value: value)
      case "if":
        return Token(kind: .if_     , value: value)
      case "else":
        return Token(kind: .else_   , value: value)
      case "while":
        return Token(kind: .while_  , value: value)
      case "void":
        return Token(kind: .void    , value: value)
      case "true":
        return Token(kind: .true_   , value: value)
      case "false":
        return Token(kind: .false_  , value: value)
      default:
        return Token(kind: .name    , value: value)
      }
    }

    // Lex type qualifiers.
    if peek() == "@" {
      take()
      take(while: { $0.isLetter })
      return Token(kind: .qualifier, value: input[start ..< index])
    }

    // Lex number literals.
    if ch.isNumber {
      take(while: { $0.isDigit })
      return Token(kind: .integer, value: input[start ..< index])
    }

    // Lex operators and punctuation.
    var kind: Token.Kind?

    switch peek(n: 2) {
    case "\\A": kind = .universal
    case "\\E": kind = .existential
    case "->" : kind = .arrow
    default   : break
    }

    if let k = kind {
      take(n: 2)
      return Token(kind: k, value: input[start ..< index])
    }

    switch peek() {
    case "&"  : kind = .and
    case "+"  : kind = .plus
    case "="  : kind = .equal
    case "."  : kind = .dot
    case ","  : kind = .comma
    case ":"  : kind = .colon
    case "!"  : kind = .exclamation
    case "?"  : kind = .question
    case "("  : kind = .leftParen
    case ")"  : kind = .rightParen
    case "["  : kind = .leftBracket
    case "]"  : kind = .rightBracket
    case "{"  : kind = .leftBrace
    case "}"  : kind = .rightBrace
    default   : break
    }

    if let k = kind {
      take()
      return Token(kind: k, value: input[start ..< index])
    }

    take()
    return Token(kind: .unknown, value: input[start ..< index])
  }

  @discardableResult
  public mutating func take(substring: String) -> Substring? {
    guard input[index...] == substring
      else { return nil }

    let end = input.index(index, offsetBy: substring.count)
    let characters = input[index ..< end]
    index = end
    return characters
  }

}
