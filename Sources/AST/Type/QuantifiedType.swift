/// A universal type.
public final class QuantifiedType: BareType {

  init(context: ASTContext, quantifier: Quantifier, params: [QuantifiedParam], base: BareType) {
    self.quantifier = quantifier
    self.params = params
    self.base = base
    super.init(context: context)
  }

  override var bytes: [UInt8] {
    var bs: [UInt8] = []
    withUnsafeBytes(of: QuantifiedType.self, { bs.append(contentsOf: $0) })
    withUnsafeBytes(of: quantifier, { bs.append(contentsOf: $0) })
    for param in params {
      bs.append(contentsOf: param.data(using: .utf8)!)
    }
    withUnsafeBytes(of: base, { bs.append(contentsOf: $0) })
    return bs
  }

  public let quantifier: Quantifier

  public let params: [QuantifiedParam]

  public let base: BareType

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    // swiftlint:disable force_cast
    return context.quantifiedType(
      quantifier: quantifier,
      params: params,
      base: base.substituting(substitutions)) as! Self
    // swiftlint:enable force_cast
  }

}

public typealias QuantifiedParam = String
