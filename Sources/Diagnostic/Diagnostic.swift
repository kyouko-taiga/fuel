import Basic

/// An in-flight diagnostic about a compilation issue.
public struct Diagnostic {

  /// Creates a new in-flight diagnostic.
  ///
  /// - Parameters:
  ///   - message: The message of the diagnostic.
  public init(
    message: String,
    ranges: [SourceRange] = []
  ) {
    self.message = message
    self.ranges = ranges
  }

  /// The message of the diagnostic.
  public let message: String

  /// A list of source range arguments.
  public let ranges: [SourceRange]

}
