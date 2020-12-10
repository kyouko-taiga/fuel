/// A universal type.
public final class UniversalType: BareType {

  init(context: ASTContext, base: BareType, params: [QuantifiedParam]) {
    self.base = base
    self.params = params
    super.init(context: context)
  }

  override var bytes: [UInt8] {
    var bs: [UInt8] = []
    withUnsafeBytes(of: UniversalType.self, { bs.append(contentsOf: $0) })
    withUnsafeBytes(of: base, { bs.append(contentsOf: $0) })
    for param in params {
      bs.append(contentsOf: param.data(using: .utf8)!)
    }
    return bs
  }

  public let base: BareType

  public let params: [QuantifiedParam]

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    // swiftlint:disable force_cast
    return context.universalType(
      base: base.substituting(substitutions),
      params: params) as! Self
    // swiftlint:enable force_cast
  }

}

public typealias QuantifiedParam = String
