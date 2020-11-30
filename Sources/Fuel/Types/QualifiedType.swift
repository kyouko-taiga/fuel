/// A (potentially) qualified type.
public final class QualifiedType: TypeBase {

  /// Creates a new qualified type.
  ///
  /// - Parameters:
  ///   - base: A type. `base` should not be a qualified type.
  ///   - assumptions: A set of qualifiers.
  public init(base: TypeBase, qualifiers: Set<TypeQualifier>) {
    precondition(!(base is QualifiedType))
    self.base = base
    self.qualifiers = qualifiers
  }

  public let base: TypeBase

  public let qualifiers: Set<TypeQualifier>

  public override var canonical: QualifiedType {
    return self
  }

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    return QualifiedType(
      base: base.substituting(substitutions),
      qualifiers: qualifiers) as! Self
  }

  public override func isEqual(to other: TypeBase) -> Bool {
    if self === other {
      return true
    } else if let rhs = other as? QualifiedType {
      return (qualifiers == rhs.qualifiers) && base.isEqual(to: rhs.base)
    } else {
      return false
    }
  }

  public override func isSubtype(of other: TypeBase) -> Bool {
    let rhs = other.canonical
    return qualifiers.isSuperset(of: rhs.qualifiers) && base.isSubtype(of: rhs.base)
  }

}

extension QualifiedType: CustomStringConvertible {

  public var description: String {
    if qualifiers.isEmpty {
      return String(describing: base)
    } else {
      let q = qualifiers.map(String.init(describing:)).joined(separator: " ")
      return "\(q) \(base)"
    }
  }

}
