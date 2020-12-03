import Foundation

/// A location in a source file.s
public struct SourceLocation {

  public init(sourceURL: URL, sourceIndex: String.Index) {
    self.sourceURL = sourceURL
    self.sourceIndex = sourceIndex
  }

  /// The source file's URL.
  public let sourceURL: URL

  /// The location's index in the source file.
  public let sourceIndex: String.Index

  /// Some unknown or unavailable source location.
  public static let unknown = SourceLocation(
      sourceURL: URL(fileURLWithPath: "/dev/null"),
      sourceIndex: "".startIndex)

}

extension SourceLocation: Comparable {

  public static func < (lhs: SourceLocation, rhs: SourceLocation) -> Bool {
    precondition(lhs.sourceURL == rhs.sourceURL)
    return lhs.sourceIndex < rhs.sourceIndex
  }

}

extension SourceLocation: Hashable {
}

public typealias SourceRange = Range<SourceLocation>
