/// A tuple type.
public final class TupleType: TypeBase {

  /// Creates a new tuple type.
  public init<S>(members: S) where S: Sequence, S.Element == TypeBase {
    self.members = Array(members)
  }

  /// The members of the tuple.
  public let members: [TypeBase]

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    return TupleType(members: members.map({ $0.substituting(substitutions) })) as! Self
  }

}

extension TupleType: CustomStringConvertible {

  public var description: String {
    return "{" + members.map(String.init(describing:)).joined(separator: ", ") + "}"
  }

}
