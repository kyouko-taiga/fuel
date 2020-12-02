/// The type of a single memory location.
///
/// Formally, a location type is a singleton type whose inhabitant designates a memory location.
public final class LocationType: BareType {

  /// Creates a new location type.
  ///
  /// - Parameter location: The name of a memory location.
  public init(location: Symbol) {
    self.location = location
  }

  /// The type's unique inhabitant.
  public let location: Symbol

  public override func isEqual(to other: BareType) -> Bool {
    guard let rhs = other as? LocationType else {
      return false
    }
    return location == rhs.location
  }

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    // swiftlint:disable force_cast
    return LocationType(location: substitutions[location] ?? location) as! Self
  }

}

extension LocationType: CustomStringConvertible {

  public var description: String {
    return "!\(location)"
  }

}
