/// The base class for all bare types.
///
/// Base types, once created, are immutable.
public class BareType {

  /// Creates a new bare type.
  init(context: ASTContext) {
    self.context = context
  }

  /// The unique data bytes of this type.
  var bytes: [UInt8] {
    return withUnsafeBytes(of: self, Array.init)
  }

  /// The AST context in which this type was uniqued.
  public unowned let context: ASTContext

  /// The type qualified by the given qualifiers.
  ///
  /// - Parameter quals: A set of type qualifiers.
  public func qualified(by quals: TypeQualSet = []) -> QualType {
    return QualType(bareType: self, quals: quals)
  }

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
    // τ ≤ τ, τ ≤ Any
    if isEqual(to: other) || other.isEqual(to: context.builtin.any) {
      return true
    }

    // τ ≤ τ, τ ≤ Junk<τ>
    if let rhs = other as? JunkType {
      return isSubtype(of: rhs.base)
    }

    return false
  }

  /// Returns the "join" of this type with another type, i.e., the least supertype of both.
  ///
  /// - Parameter other: Another semantic type.
  public func join(with other: BareType) -> BareType {
    return isEqual(to: other)
      ? self
      : context.builtin.any
  }

}
