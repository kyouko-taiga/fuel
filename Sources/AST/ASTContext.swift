import Basic
import Diagnostic

/// An AST context holding references to various resources throughout all compilation stages.
public final class ASTContext {

  /// Creates a new AST context.
  public init() {
    builtin = BuiltinModule(context: self)
    modules[builtin.id] = builtin
  }

  /// The modules loaded in the AST context.
  public var modules: [Module.ID: Module] = [:]

  /// The built-in module.
  public private(set) var builtin: BuiltinModule!

  /// The types created in the AST context.
  public private(set) var types: [[UInt8]: BareType] = [:]

  public private(set) lazy var errorType: ErrorType = { [unowned self] in
    let ty = ErrorType(context: self)
    types[ty.bytes] = ty
    return ty
  }()

  private func insert<T>(type: T) -> T where T: BareType {
    let bytes = type.bytes
    if let existing = types[bytes] {
      return existing as! T
    }

    types[bytes] = type
    return type
  }

  /// Creates a built-in type.
  func builtinType(name: String) -> BuiltinType {
    let ty = BuiltinType(context: self, name: name)
    types[ty.bytes] = ty
    return ty
  }

  /// Creates a bundled type.
  ///
  /// - Parameters:
  ///   - base: A type. `base` should not be a bundled type.
  ///   - assumptions: A set of assumptions.
  public func bundledType(base: BareType, assumptions: TypingContext) -> BundledType {
    let ty = BundledType(context: self, base: base, assumptions: assumptions)
    return insert(type: ty)
  }

  /// Creates a function type.
  ///
  /// - Parameters:
  ///   - params: The function's parameters.
  ///   - output: The function's output type.
  public func funcType(params: [QualType], output: QualType) -> FuncType {
    let ty = FuncType(context: self, params: params, output: output)
    return insert(type: ty)
  }

  /// Creates a junk type.
  ///
  /// - Parameter base: A type describing the underlying layout.
  public func junkType(base: BareType) -> JunkType {
    let ty = JunkType(context: self, base: base)
    return insert(type: ty)
  }

  /// Creates a location type.
  ///
  /// - Parameter location: The name of a memory location.
  public func locationType(location: Symbol) -> LocationType {
    let ty = LocationType(context: self, location: location)
    return insert(type: ty)
  }

  /// Creates a tuple type.
  ///
  /// - Parameter members: The members of the tuple.
  public func tupleType<S>(members: S) -> TupleType where S: Sequence, S.Element == QualType {
    let ty = TupleType(context: self, members: members)
    return insert(type: ty)
  }

  /// Creates a new universal type.
  ///
  /// - Parameters:
  ///   - base: A type with unbound quantified parameters.
  ///   - params: An array of universally quantified parameter names.
  public func universalType(base: BareType, params: [QuantifiedParam]) -> UniversalType {
    let ty = UniversalType(context: self, base: base, params: params)
    return insert(type: ty)
  }

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
