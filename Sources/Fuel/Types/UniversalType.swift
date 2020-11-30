/// A universal type.
public final class UniversalType: TypeBase {

  /// Creates a new universal type.
  public init(base: TypeBase, params: [QuantifiedParam]) {
    self.base = base
    self.params = params
  }

  public let base: TypeBase

  public let params: [QuantifiedParam]

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    return UniversalType(
      base: base.substituting(substitutions),
      params: params) as! Self
  }

}

public typealias QuantifiedParam = String
