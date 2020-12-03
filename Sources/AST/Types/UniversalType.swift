/// A universal type.
public final class UniversalType: BareType {

  /// Creates a new universal type.
  public init(base: BareType, params: [QuantifiedParam]) {
    self.base = base
    self.params = params
  }

  public let base: BareType

  public let params: [QuantifiedParam]

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    // swiftlint:disable force_cast
    return UniversalType(
      base: base.substituting(substitutions),
      params: params) as! Self
    // swiftlint:enable force_cast
  }

}

public typealias QuantifiedParam = String
