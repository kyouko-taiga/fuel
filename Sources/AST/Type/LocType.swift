/// The type of a single memory location.
///
/// Formally, a location type is a singleton type whose inhabitant designates a memory location.
public final class LocType: BareType {

  init(context: ASTContext, location: Symbol) {
    self.location = location
    super.init(context: context)
  }

  override var bytes: [UInt8] {
    var bs: [UInt8] = []
    withUnsafeBytes(of: JunkType.self, { bs.append(contentsOf: $0) })
    withUnsafeBytes(of: location, { bs.append(contentsOf: $0) })
    withUnsafeBytes(of: context, { bs.append(contentsOf: $0) })
    return bs
  }

  /// The type's unique inhabitant.
  public let location: Symbol

  public override func substituting(_ substitutions: [Symbol: Symbol]) -> Self {
    // swiftlint:disable force_cast
    return context.locType(location: substitutions[location] ?? location) as! Self
  }

}

extension LocType: CustomStringConvertible {

  public var description: String {
    return "!\(location)"
  }

}
