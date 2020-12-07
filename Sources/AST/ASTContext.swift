import Basic
import Diagnostic

/// An AST context holding references to various resources throughout all compilation stages.
public final class ASTContext {

  /// Creates a new AST context.
  public init() {
    modules = [Module.builtin.id: Module.builtin]
  }

  /// The modules loaded in the AST context.
  public var modules: [Module.ID: Module]

  /// The consumer for all in-flight diagnostics.
  public var diagnosticConsumer: DiagnosticConsumer?

  /// Reports an in-flight diagnostic.
  ///
  /// This method returns an instance of a diagnostic builder that you can use to attach additional
  /// information to the diagnostic. The diagnostic is emitted as soon as the last reference on the
  /// builder is dropped.
  ///
  ///     do {
  ///       let builder = context.report(message: "something is wrong")
  ///       builder.set(location: someLocation)
  ///       builder.add(range: someSourceRange)
  ///     } // <- the diagnostic is emitted here
  ///
  /// - Parameters:
  ///   - message: A message describing the issue.
  ///   - location: The source location from which the diagnostic originates.
  @discardableResult
  public func report(message: String) -> DiagnosticBuilder {
    return DiagnosticBuilder(message: message, consumer: { [unowned self] in
      if let loc = $1 {
        self.diagnosticConsumer?.consume($0, at: loc)
      } else {
        self.diagnosticConsumer?.consume($0)
      }
    })
  }

}
