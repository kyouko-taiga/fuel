/// A set of type qualifiers.
public struct TypeQualSet: OptionSet {

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public let rawValue: Int

  /// No qualifier.
  public static let none = TypeQualSet([])

  /// The type of an unowned value.
  ///
  /// The `unowned` qualifier applies on cell assumptions. It indicates that the cell is must not
  /// be owned. This typically designates non-GCed heap-memory memory.
  public static let unowned = TypeQualSet(rawValue: 1 << 0)

}

extension TypeQualSet: CustomStringConvertible {

  public var description: String {
    var quals: [String] = []

    if contains(.unowned) {
      quals.append("@unowned")
    }

    return quals.joined(separator: " ")
  }

}
