/// A function type.
public final class FuncType: BareType {

  /// Initializes a function type.
  ///
  /// Parameters:
  /// - params: The function's parameters.
  /// - output: The function's output type.
  public init(params: [QualType], output: QualType) {
    self.params = params
    self.output = output
  }

  /// The function's parameters.
  public let params: [QualType]

  /// The function's output type.
  public let output: QualType

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    // swiftlint:disable force_cast
    return FuncType(
      params: params.map({ $0.substituting(substitutions) }),
      output: output.substituting(substitutions)) as! Self
    // swiftlint:enable force_cast
  }

}
