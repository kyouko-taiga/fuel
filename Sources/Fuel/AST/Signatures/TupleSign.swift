public final class TupleSign: TypeSign {

  public init(members: [TypeSign]) {
    self.members = members
  }

  public var members: [TypeSign]

  public var type: QualType?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension TupleSign: CustomStringConvertible {

  public var description: String {
    let body = members.map(String.init(describing:)).joined(separator: ", ")
    return "{ \(body) }"
  }

}
