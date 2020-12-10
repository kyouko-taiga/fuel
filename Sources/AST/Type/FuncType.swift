/// A function type.
public final class FuncType: BareType {

  init(context: ASTContext, params: [QualType], output: QualType) {
    self.params = params
    self.output = output
    super.init(context: context)
  }

  override var bytes: [UInt8] {
    var bs: [UInt8] = []
    withUnsafeBytes(of: BundledType.self, { bs.append(contentsOf: $0) })
    for param in params {
      withUnsafeBytes(of: param, { bs.append(contentsOf: $0) })
    }
    withUnsafeBytes(of: output, { bs.append(contentsOf: $0) })
    withUnsafeBytes(of: context, { bs.append(contentsOf: $0) })
    return bs
  }

  /// The function's parameters.
  public let params: [QualType]

  /// The function's output type.
  public let output: QualType

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    // swiftlint:disable force_cast
    return context.funcType(
      params: params.map({ $0.substituting(substitutions) }),
      output: output.substituting(substitutions)) as! Self
    // swiftlint:enable force_cast
  }

}
