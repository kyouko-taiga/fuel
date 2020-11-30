/// The base class for all fully resolved semantic types.
///
/// Types, once created, are immutable.
public class TypeBase {

  /// The type's canonical form.
  public var canonical: QualifiedType {
    return QualifiedType(base: self, qualifiers: [])
  }

  /// The type obtained by applying the given substitution.
  public func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    return self
  }

  /// Returns whether this type is equal to another one.
  ///
  /// - Parameter other: Another semantic type.
  public func isEqual(to other: TypeBase) -> Bool {
    return self === other
  }

  /// Returns whether this type is a subtype of another one.
  ///
  /// - Parameter other: Another semantic type.
  public func isSubtype(of other: TypeBase) -> Bool {
    return isEqual(to: other) || other.isEqual(to: BuiltinType.junk)
  }

  /// Returns the "join" of this type with another type `τ`, i.e., the least supertype of both.
  ///
  /// - Parameter other: Another semantic type.
  public func join(with other: TypeBase) -> TypeBase {
    return isEqual(to: other)
      ? self
      : BuiltinType.junk
  }

}
