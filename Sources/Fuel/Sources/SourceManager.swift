import Foundation

/// A source manager that handles files on a local file system.
public final class SourceManager {

  /// Creates a new local source manager.
  public init() throws {
    let manager = FileManager.default
    let currentDirectoryURL = URL(fileURLWithPath: manager.currentDirectoryPath, isDirectory: true)

    temporaryDirectoryURL = try manager.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: currentDirectoryURL,
      create: true)
  }

  /// The URL of a temporary directory.
  private let temporaryDirectoryURL: URL

  /// A file content cache.
  private var contentCache: [URL: String] = [:]

  /// Loads a source file from a local path.
  ///
  /// - Parameters:
  ///   - path: A local path.
  ///   - encoding: The character encoding of the file at `path`.
  public func load(
    contentsOf path: String,
    encoding: String.Encoding = .utf8
  ) throws -> SourceFile {
    let url = URL(fileURLWithPath: path).absoluteURL
    if contentCache[url] != nil {
      return SourceFile(manager: self, url: url)
    }

    contentCache[url] = try String(contentsOf: url, encoding: encoding)
    return SourceFile(manager: self, url: url)
  }

  /// Loads a source file from a string buffer.
  ///
  /// - Parameter string: A character string with the contents of the source file.
  public func load(string: String) -> SourceFile {
    let url = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString)
    contentCache[url] = string
    return SourceFile(manager: self, url: url)
  }

  /// Returns the contents of a managed source file.
  ///
  /// - Parameter url: The URL of a managed source file.
  public func contents(of url: URL) -> String {
    return contentCache[url]!
  }

//  /// A file content cache.
//  private var contentCache: [URL: String] = [:]
//
//  /// Loads a source file from an in-memory buffer.
//  @discardableResult
//  public func load()
//
//  /// Loads a source file from the given URL.
//  ///
//  /// - Parameters:
//  ///   - location: The URL of a source file.
//  ///   - encoding: The file's encoding.
//  @discardableResult
//  public func load(contentsOf url: URL, encoding: String.Encoding = .utf8) throws -> URL {
//    let location = url.standardized
//    if let contents = contentCache[location] {
//      return contents
//    }
//
//    URL(string: "memory://aa")
//
//    let contents = try String(contentsOf: location, encoding: encoding)
//    contentCache[url] = contents
//    return location
//  }
//
//  /// Loads a source file from the given file path.
//  ///
//  /// - Parameters:
//  ///   - path: A file path.
//  ///   - encoding: The file's encoding.
//  @discardableResult
//  public func load(contentsOfFile path: String, encoding: String.Encoding) throws -> URL {
//    return try load(contentsOf: URL(fileURLWithPath: path), encoding: encoding)
//  }
//
//  /// Returns the source location of the given line and column in the specified source file.
//  ///
//  /// - Parameters:
//  ///   - line: A 1-based line index.
//  ///   - column: A 1-based column index.
//  ///   - sourceID: The identifier of a source file loaded by this manager.
//  public func location(line: Int, column: Int, in sourceID: SourceID) -> SourceLocation {
//    precondition(line > 0 && column > 0)
//    let buffer = contents(of: sourceID)
//    var i = buffer.startIndex
//    var l = line - 1
//    while l > 0 {
//      if buffer[i].isNewline {
//        l = l - 1
//      }
//      i = buffer.index(after: i)
//    }
//    return SourceLocation(sourceID: sourceID, sourceIndex: buffer.index(i, offsetBy: column - 1))
//  }
//
//  public func location(of index: String.Index, in sourceID: SourceID) -> SourceLocation {
//    return SourceLocation(sourceID: sourceID, sourceIndex: index)
//  }

}
