import Basic

/// A type bundled with a set of assumptions.
///
/// Bundled types associate a value with some knowledge about its surrounding typing environment,
/// typically to pass this value across function boundaries or store it in a field. For example,
/// the type of a function parameter expecting a dereferenceable pointer to `τ` is a bundled type
/// `!a + [a: τ]`, inhabited by a memory location `a` and the assumption that a value of type `τ`
/// is stored there.
public final class BundledType: BareType {

  /// Creates a new bundled type.
  ///
  /// - Parameters:
  ///   - base: A type. `base` should not be a bundled type.
  ///   - assumptions: A set of assumptions.
  public init(base: BareType, assumptions: TypingContext) {
    precondition(!(base is BundledType))
    self.base = base
    self.assumptions = assumptions
  }

  /// A type.
  public var base: BareType

  /// A set of assumptions.
  public var assumptions: TypingContext

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    let newAssumptions = TypingContext(
      uniqueKeysWithValues: assumptions.map({ (key, value) in
        (substitutions[key] ?? key, value.substituting(substitutions))
      }))

    // swiftlint:disable force_cast
    return BundledType(
      base: base.substituting(substitutions),
      assumptions: newAssumptions) as! Self
    // swiftlint:enable force_cast
  }

}
