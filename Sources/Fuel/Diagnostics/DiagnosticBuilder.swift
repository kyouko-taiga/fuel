/// A helper class to build in-flight diagnostics.
///
/// Instances of this class are returned by the method `report(message:at:)` of a compiler context,
/// and can be used to attach additional information to a diagnostic before it is emitted to the
/// context's diagnostic consumer.
///
/// The diagnostic is emitted automatically when the last reference on this class is dropped.
public final class DiagnosticBuilder {

  init(context: CompilerContext, message: String) {
    self.context = context
    self.message = message
  }

  deinit {
    let diagnostic = Diagnostic(message: message, ranges: ranges)
    if let location = self.location {
      context.diagnosticConsumer?.consume(diagnostic, at: location)
    } else {
      context.diagnosticConsumer?.consume(diagnostic)
    }
  }

  /// The compiler context which created the builder.
  public unowned let context: CompilerContext

  /// A message describing the diagnostic.
  public let message: String

  /// The source location at which the diagnostic should be reported.
  public var location: SourceLocation?

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
