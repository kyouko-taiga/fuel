import Foundation

/// A source manager that handles files on a local file system.
public final class SourceManager {

  /// Creates a new local source manager.
  public init() {
  }

  /// A file content cache.
  private var contentCache: [URL: String] = [:]

  /// Loads a source file from the URL of a local file.
  ///
  /// - Parameters:
  ///   - url: The URL of a local file.
  ///   - encoding: The character encoding of the file at `path`.
  public func load(
    contentsOf url: URL,
    encoding: String.Encoding = .utf8
  ) throws -> SourceFile {
    let url = url.absoluteURL
    if contentCache[url] != nil {
      return SourceFile(manager: self, url: url)
    }

    contentCache[url] = try String(contentsOf: url, encoding: encoding)
    return SourceFile(manager: self, url: url)
  }

  /// Loads a source file from a local path.
  ///
  /// - Parameters:
  ///   - path: A local path.
  ///   - encoding: The character encoding of the file at `path`.
  public func load(
    contentsOf path: String,
    encoding: String.Encoding = .utf8
  ) throws -> SourceFile {
    return try load(contentsOf: URL(fileURLWithPath: path), encoding: encoding)
  }

  /// Loads a source file from a string buffer.
  ///
  /// - Parameter string: A character string with the contents of the source file.
  public func load(string: String) -> SourceFile {
    let url = URL(string: "memory://" + UUID().uuidString)!
    contentCache[url] = string
    return SourceFile(manager: self, url: url)
  }

  /// Returns the contents of a managed source file.
  ///
  /// - Parameter url: The URL of a managed source file.
  public func contents(of url: URL) -> String {
    return contentCache[url]!
  }

}
