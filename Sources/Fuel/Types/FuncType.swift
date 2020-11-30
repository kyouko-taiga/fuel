/// A function type.
public final class FuncType: TypeBase {

  /// Initializes a function type.
  ///
  /// Parameters:
  /// - params: The function's parameters.
  /// - output: The function's output type.
  public init(params: [TypeBase], output: TypeBase) {
    self.params = params
    self.output = output
  }

  /// The function's parameters.
  public let params: [TypeBase]

  /// The function's output type.
  public let output: TypeBase

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    return FuncType(
      params: params.map({ $0.substituting(substitutions) }),
      output: output.substituting(substitutions)) as! Self
  }

}
