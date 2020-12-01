/// A type packed with a set of assumptions.
///
/// Packed types associate a value with some knowledge about its surrounding typing environment,
/// typically to pass this value across function boundaries or store it in a field. For example,
/// the type of a function parameter expecting a dereferenceable pointer to `τ` is a packed type
/// `!a + [a: τ]`, inhabited by a memory location `a` and the assumption that a value of type `τ`
/// is stored there.
public final class PackedType: BareType {

  /// Creates a new packed type.
  ///
  /// - Parameters:
  ///   - base: A type. `base` should not be a packed type.
  ///   - assumptions: A set of assumptions.
  public init(base: BareType, assumptions: TypingContext) {
    precondition(!(base is PackedType))
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

    return PackedType(base: base.substituting(substitutions), assumptions: newAssumptions) as! Self
  }

}
