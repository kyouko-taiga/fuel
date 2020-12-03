import Basic

public struct Token {

  /// The token's kind.
  public let kind: Kind

  /// The text of the token as it appears in the source file.
  public let value: Substring

  /// The source file from which the token originates.
  public let source: SourceFile

  /// The range of the token in the source file.
  @inlinable public var range: SourceRange {
    return source.location(at: value.startIndex) ..< source.location(at: value.endIndex)
  }

  public var start: (line: Int, column: Int) {
    let lines = value.base[value.base.startIndex ..< value.startIndex]
      .split(separator: "\n")

    guard let last = lines.last
      else { return (1, 1) }

    let columns = value.base[last.startIndex ..< value.startIndex]
    return (lines.count, columns.count + 1)
  }

  public var lines: ClosedRange<Int> {
    let lower = value.base[value.base.startIndex ..< value.startIndex]
      .filter({ $0.isNewline })
      .count
    let upper = lower + value.filter({ $0.isNewline }).count
    return lower ... upper
  }

  public enum Kind {

    case name

    case qualifier

    case junk

    case void

    case true_

    case false_

    case integer

    case func_

    case salloc

    case halloc

    case call

    case addr

    case free

    case store

    case load

    case return_

    case if_

    case else_

    case while_

    case and

    case plus

    case universal

    case existential

    case arrow

    case dot

    case equal

    case colon

    case comma

    case exclamation

    case question

    case leftParen

    case rightParen

    case leftBracket

    case rightBracket

    case leftBrace

    case rightBrace

    case newline

    case eof

    case unknown

  }

}

extension Token: CustomDebugStringConvertible {

  public var debugDescription: String {
    return String(describing: kind)
  }

}
