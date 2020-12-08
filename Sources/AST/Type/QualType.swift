/// A (potentially) qualified semantic type.
public struct QualType {

  /// Creates a new qualified type.
  ///
  /// - Parameters:
  ///   - bareType: A bare type.
  ///   - quals: A set of qualifiers.
  public init(bareType: BareType, quals: TypeQualSet = .none) {
    self.bareType = bareType
    self.quals = quals
  }

  /// The underlying bare (i.e., unqualified) type.
  public var bareType: BareType

  /// The type's qualifiers.
  public var quals: TypeQualSet

  /// This type, refined with the specified qualifiers.
  ///
  /// - Parameter quals: A set of type qualifiers to add.
  public func with(_ quals: TypeQualSet) -> QualType {
    return QualType(bareType: bareType, quals: self.quals.union(quals))
  }

  /// This type, stripped from the specified qualifiers.
  ///
  /// - Parameter quals: A set of type qualifiers to remove.
  public func without(_ quals: TypeQualSet) -> QualType {
    return QualType(bareType: bareType, quals: self.quals.subtracting(quals))
  }

  /// The (qualified) base of the underlying bundled type, separated from its assumptions.
  public var opened: (base: QualType, assumptions: TypingContext)? {
    if let bundle = bareType as? BundledType {
      return (QualType(bareType: bundle.base, quals: quals), bundle.assumptions)
    } else {
      return nil
    }
  }

  /// Defererences the type at the given path.
  ///
  /// - Parameter path: A collection of offsets.
  public func dereference<C>(path: C) -> QualType? where C: Collection, C.Element == Int {
    guard let i = path.first else {
      return self
    }

    // TODO: Apply relevant qualifiers to the dereferenced type.
    switch bareType {
    case let tupleType as TupleType:
      return tupleType.members[i].dereference(path: path.dropFirst())

    case let junkType as JunkType:
      return junkType.base.qualified().dereference(path: path)

    default:
      return nil
    }
  }

  /// Returns the type obtained by substituting the given type at the specified path.
  ///
  /// An aggregate type is a tree, whose each node is identified by a unique sequence of member
  /// offsets. This method returns a copy of this tree, where the node identified by the specified
  /// path has been substituted for the given type.
  ///
  /// - Parameters:
  ///   - path: A collection of member offsets identifying a specific type in the aggregate. `path`
  ///     must be valid to dereference `bareType`.
  ///   - substitute: A substitute type.
  public func substituting<C>(typeAt path: C, with substitute: QualType) -> QualType
  where C: Collection, C.Element == Int
  {
    guard let i = path.first else { return substitute }

    var members: [QualType] = []

    switch self.bareType {
    case let tupleType as TupleType:
      members = tupleType.members

    case let junkType as JunkType:
      guard let tupleType = junkType.base as? TupleType else { fallthrough }
      members = tupleType.members.map({ member in
        JunkType(base: member.bareType).qualified(by: member.quals)
      })

    default:
      fatalError("\(self) is not dereferencable")
    }

    members[i] = members[i].substituting(typeAt: path.dropFirst(), with: substitute)
    return TupleType(members: members).qualified(by: self.quals)
  }

  /// Returns the type obtained by applying the given symbol substitution table.
  ///
  /// - Parameter substitutions: A table mapping the symbols to susbtitute onto their substitution.
  public func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    return QualType(bareType: bareType.substituting(substitutions), quals: quals)
  }

  /// Returns whether this type is a subtype of another one.
  ///
  /// - Parameter other: Another qualified type.
  public func isSubtype(of other: QualType) -> Bool {
    return quals.isSuperset(of: other.quals) && bareType.isSubtype(of: other.bareType)
  }

  /// Returns the "join" of this type with another type, i.e., the least supertype of both.
  ///
  /// - Parameter other: Another qualified type.
  public func join(with other: QualType) -> QualType {
    return QualType(
      bareType: bareType.join(with: other.bareType),
      quals: quals.intersection(other.quals))
  }

  public static func <= (lhs: QualType, rhs: QualType) -> Bool {
    return lhs.quals.isSuperset(of: rhs.quals) && lhs.bareType.isSubtype(of: rhs.bareType)
  }

}

extension QualType: Equatable {

  public static func == (lhs: QualType, rhs: QualType) -> Bool {
    return (lhs.quals == rhs.quals) && lhs.bareType.isEqual(to: rhs.bareType)
  }

}

extension QualType: CustomStringConvertible {

  public var description: String {
    if quals.isEmpty {
      return String(describing: bareType)
    } else {
      return "\(quals) \(bareType)"
    }
  }

}
