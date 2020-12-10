/// A tuple type.
public final class TupleType: BareType {

  init<S>(context: ASTContext, members: S) where S: Sequence, S.Element == QualType {
    self.members = Array(members)
    super.init(context: context)
  }

  override var bytes: [UInt8] {
    var bs: [UInt8] = []
    withUnsafeBytes(of: TupleSign.self, { bs.append(contentsOf: $0) })
    for member in members {
      withUnsafeBytes(of: member, { bs.append(contentsOf: $0) })
    }
    return bs
  }

  /// The members of the tuple.
  public let members: [QualType]

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    // swiftlint:disable:next force_cast
    return context.tupleType(members: members.map({ $0.substituting(substitutions) })) as! Self
  }

}

extension TupleType: CustomStringConvertible {

  public var description: String {
    return "{" + members.map(String.init(describing:)).joined(separator: ", ") + "}"
  }

}
