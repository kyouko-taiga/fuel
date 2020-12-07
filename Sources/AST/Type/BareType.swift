/// The base class for all bare types.
///
/// Base types, once created, are immutable.
public class BareType {

  /// The type obtained by applying the given substitution.
  public func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    return self
  }

  /// Returns whether this type is equal to another one.
  ///
  /// - Parameter other: Another semantic type.
  public func isEqual(to other: BareType) -> Bool {
    return self === other
  }

  /// Returns whether this type is a subtype of another one.
  ///
  /// - Parameter other: Another semantic type.
  public func isSubtype(of other: BareType) -> Bool {
    return isEqual(to: other) || other.isEqual(to: BuiltinType.any)
  }

  /// Returns the "join" of this type with another type, i.e., the least supertype of both.
  ///
  /// - Parameter other: Another semantic type.
  public func join(with other: BareType) -> BareType {
    return isEqual(to: other)
      ? self
      : BuiltinType.any
  }

}
