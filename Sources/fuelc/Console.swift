import Foundation
import Fuel

struct Console: DiagnosticConsumer {

  var sourceManager: SourceManager

  func consume(_ diagnostic: Diagnostic) {
    print(diagnostic.message)
  }

  func consume(_ diagnostic: Diagnostic, at location: SourceLocation) {
    // Load the contents of the source file.
    let contents = sourceManager.contents(of: location.sourceURL)

    // Identify the line and column at which the diagnostic is located.
    let prefix = contents.prefix(upTo: location.sourceIndex)
    let lineIndex = prefix.occurences(of: "\n")
    let columnIndex = prefix.distance(
      from: prefix.lastIndex(of: "\n") ?? prefix.startIndex,
      to: location.sourceIndex)

    // Print the diagnostic.
    let filename = location.sourceURL.path(relativeTo: FileManager.default.currentDirectoryPath)
    print("\(filename):\(lineIndex + 1):\(columnIndex + 1): ", terminator: "")
    print(diagnostic.message)

    // Print the source ranges, if any.
    for range in diagnostic.ranges {
      // Extract the line containing the range.
      let rangeStart = range.lowerBound.sourceIndex
      let lineStart = contents
        .prefix(upTo: rangeStart)
        .lastIndex(of: "\n")
        .map(contents.index(after:))
        ?? contents.startIndex
      let line = contents.suffix(from: lineStart).prefix(while: { $0 != "\n" })
      print(line)

      // Draw a "line" under the range.
      let padding = contents.distance(from: lineStart, to: rangeStart)
      let trail = contents.distance(
        from: contents.index(after: rangeStart),
        to: min(range.upperBound.sourceIndex, line.endIndex))

      print(String(repeating: " ", count: padding), terminator: "")
      print("^", terminator: "")
      print(String(repeating: "~", count: trail))    }
  }

}

#if os(macOS) || os(Linux) || os(FreeBSD)
extension Console {

  static var hasColorSupport: Bool {
    guard let term = getenv("TERM")
      else { return false }
    return term.pointee != 0
  }

}
#endif
