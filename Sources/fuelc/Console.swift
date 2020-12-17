import Foundation

import Basic
import Diagnostic
import Fuel

struct Console: DiagnosticConsumer {

  var sourceManager: SourceManager

  func consume(_ diagnostic: Diagnostic) {
    print(diagnostic.message)
  }

  func consume(_ diagnostic: Diagnostic, at location: SourceRange.Bound) {
    // Load the contents of the source file.
    guard let source = sourceManager.source(containing: location) else {
      consume(diagnostic)
      return
    }

    // Identify the line and column at which the diagnostic is located.
    let lineIndex = source.lineIndex(at: location)
    let columnIndex = source.columnIndex(at: location)

    // Print the diagnostic.
    let filename = source.url.path(relativeTo: FileManager.default.currentDirectoryPath)
    print("\(filename):\(lineIndex):\(columnIndex): ", terminator: "")
    print(diagnostic.message)

    // Print the source ranges, if any.
    for range in diagnostic.ranges {
      // Extract the text of the line containing the range.
      let line = source.line(containing: location)
      print(line)

      // Draw a "line" under the range.
      let padding = source.distance(from: line.startIndex, to: location)
      let trail = source.distance(
        from: range.lowerBound,
        to: min(range.upperBound, line.endIndex))

      print(String(repeating: " ", count: padding), terminator: "")
      if trail > 1 {
        print(String(repeating: "~", count: trail))
      } else {
        print("^")
      }
    }
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
