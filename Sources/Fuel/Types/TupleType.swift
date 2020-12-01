/// A tuple type.
public final class TupleType: BareType {

  /// Creates a new tuple type.
  public init<S>(members: S) where S: Sequence, S.Element == QualType {
    self.members = Array(members)
  }

  /// The members of the tuple.
  public let members: [QualType]

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    return TupleType(members: members.map({ $0.substituting(substitutions) })) as! Self
  }

}

extension TupleType: CustomStringConvertible {

  public var description: String {
    return "{" + members.map(String.init(describing:)).joined(separator: ", ") + "}"
  }

}
