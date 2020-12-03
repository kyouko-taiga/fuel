import Foundation

/// A handle to a source file, loaded by a source manager
public struct SourceFile {

  /// The manager that loaded the source file.
  public unowned let manager: SourceManager

  /// The source file's URL.
  public let url: URL

  /// The contents of the soruce file.
  @inlinable public var contents: String {
    return manager.contents(of: url)
  }

  /// Returns the source location at the given string index.
  @inlinable public func location(at index: String.Index) -> SourceLocation {
    return SourceLocation(sourceURL: url, sourceIndex: index)
  }

  /// Returns the 1-based line and column indices of the given location in this source.
  public func caretPosition(at location: SourceLocation) -> (lineIndex: Int, columnIndex: Int) {
    // Identify the line and column at which the diagnostic is located.
    let prefix = contents.prefix(upTo: location.sourceIndex)
    let lineIndex = prefix.occurences(of: "\n")
    let columnIndex = prefix.distance(
      from: prefix.lastIndex(of: "\n") ?? prefix.startIndex,
      to: location.sourceIndex)

    return (lineIndex + 1, columnIndex + 1)
  }

}

extension Substring {

  func occurences(of character: Character) -> Int {
    var count = 0
    for ch in self where ch == character {
      count += 1
    }
    return count
  }

}
