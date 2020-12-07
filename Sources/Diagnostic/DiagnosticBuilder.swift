import Basic

/// A helper class to build in-flight diagnostics.
///
/// Instances of this class are returned by the method `report(message:at:)` of an AST context, and
/// can be used to attach additional information to a diagnostic before it is emitted.
///
/// The diagnostic is emitted automatically when the last reference on this class is dropped.
public final class DiagnosticBuilder {

  public init(message: String, consumer: @escaping (Diagnostic, SourceLocation?) -> Void) {
    self.message = message
    self.consumer = consumer
  }

  deinit {
    let diagnostic = Diagnostic(message: message, ranges: ranges)
    consumer(diagnostic, location)
  }

  /// A message describing the diagnostic.
  public let message: String

  /// The source location at which the diagnostic should be reported.
  public var location: SourceLocation?

  /// A closure that can consume the diagnostic when it is emitted.
  public var consumer: (Diagnostic, SourceLocation?) -> Void

  /// Sets the source location at which the diagnostic should be reported.
  @discardableResult
  public func set(location: SourceLocation?) -> DiagnosticBuilder {
    self.location = location
    return self
  }

  /// A list of source range arguments.
  public var ranges: [SourceRange] = []

  /// Adds a source range to the diagnostic.
  ///
  /// - Parameter range: A source range.
  @discardableResult
  public func add(range: SourceRange?) -> DiagnosticBuilder {
    if let r = range {
      ranges.append(r)
    }
    return self
  }

}
