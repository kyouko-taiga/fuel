// swiftlint:disable comma cyclomatic_complexity
import Basic

/// An iterator that tokenizes the contents of a source file.
public struct Lexer: IteratorProtocol, Sequence, StreamProcessor {

  /// Creates a new lexer for the given source file.
  ///
  /// - Parameter source: A source file.
  public init(source: SourceFile) {
    self.source = source
    self.input = source.contents
    self.index = input.startIndex
  }

  /// The source file being tokenized.
  private let source: SourceFile

  /// The contents of the file being tokenized.
  public let input: String

  /// The index from which the file is being tokenized.
  public var index: String.Index

  /// A boolean value that indicates whether the source file has been completed processed.
  private var depleted = false

  public mutating func next() -> Token? {
    guard !depleted
      else { return nil }

    // Ignore whitespaces.
    take(while: { $0.isWhitespace && !$0.isNewline })

    // Ignore comments.
    if peek(n: 2) == "//" {
      take(while: { !$0.isNewline })
    }

    // Lex the end of file.
    guard let ch = peek() else {
      depleted = true
      return Token(kind: .eof, value: input[index ..< index], source: source)
    }

    let start = index

    // Merge new lines with subsequent whitespaces.
    if ch.isNewline {
      take(while: { $0.isWhitespace })
      return Token(kind: .newline, value: input[start ... start], source: source)
    }

    // Lex identifiers and keywords.
    if ch.isLetter || ch == "_" {
      let identifier = take(while: { $0.isLetter || $0.isDigit || $0 == "_" })
      let value = input[start ..< index]

      switch identifier {
      case "return":
        return Token(kind: .return_ , value: value, source: source)
      case "func":
        return Token(kind: .func_   , value: value, source: source)
      case "salloc":
        return Token(kind: .salloc  , value: value, source: source)
      case "halloc":
        return Token(kind: .halloc  , value: value, source: source)
      case "call":
        return Token(kind: .call    , value: value, source: source)
      case "addr":
        return Token(kind: .addr    , value: value, source: source)
      case "free":
        return Token(kind: .free    , value: value, source: source)
      case "store":
        return Token(kind: .store   , value: value, source: source)
      case "load":
        return Token(kind: .load    , value: value, source: source)
      case "if":
        return Token(kind: .if_     , value: value, source: source)
      case "else":
        return Token(kind: .else_   , value: value, source: source)
      case "while":
        return Token(kind: .while_  , value: value, source: source)
      case "junk":
        return Token(kind: .junk    , value: value, source: source)
      case "void":
        return Token(kind: .void    , value: value, source: source)
      case "true":
        return Token(kind: .true_   , value: value, source: source)
      case "false":
        return Token(kind: .false_  , value: value, source: source)
      default:
        return Token(kind: .name    , value: value, source: source)
      }
    }

    // Lex type qualifiers.
    if peek() == "@" {
      take()
      take(while: { $0.isLetter })
      return Token(kind: .qualifier, value: input[start ..< index], source: source)
    }

    // Lex number literals.
    if ch.isNumber {
      take(while: { $0.isDigit })
      return Token(kind: .integer, value: input[start ..< index], source: source)
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
      return Token(kind: k, value: input[start ..< index], source: source)
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
      return Token(kind: k, value: input[start ..< index], source: source)
    }

    take()
    return Token(kind: .unknown, value: input[start ..< index], source: source)
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
