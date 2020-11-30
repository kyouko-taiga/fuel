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

}
