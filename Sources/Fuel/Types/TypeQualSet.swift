/// A set of type qualifiers.
public struct TypeQualSet: OptionSet {

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public let rawValue: Int

  /// No qualifier.
  public static let none      = TypeQualSet([])

  /// A type identifying an assumption that is not bound to any scope.
  public static let unscoped  = TypeQualSet(rawValue: 1 << 0)

}
