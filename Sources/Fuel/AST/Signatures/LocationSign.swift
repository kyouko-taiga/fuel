/// The signature of a location type.
public final class LocationSign: TypeSign {

  public init(location: IdentExpr) {
    self.location = location
  }

  public var location: IdentExpr

  public var type: TypeBase?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension LocationSign: CustomStringConvertible {

  public var description: String {
    return "!\(location)"
  }

}
