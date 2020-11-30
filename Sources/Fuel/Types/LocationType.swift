/// The type of a single memory location.
///
/// Formally, a location type is a singleton type whose inhabitant designates a memory location.
public final class LocationType: TypeBase {

  /// Creates a new location type.
  ///
  /// - Parameter location: The name of a memory location.
  public init(location: Symbol) {
    self.location = location
  }

  /// The type's unique inhabitant.
  public let location: Symbol


  public override func isEqual(to other: TypeBase) -> Bool {
    guard let rhs = other as? LocationType else {
      return false
    }
    return location == rhs.location
  }

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    return LocationType(location: substitutions[location] ?? location) as! Self
  }

}

extension LocationType: CustomStringConvertible {

  public var description: String {
    return "!\(location)"
  }

}
