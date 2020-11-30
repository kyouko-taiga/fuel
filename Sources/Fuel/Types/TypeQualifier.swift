/// A type qualifier.
public enum TypeQualifier {

  /// A type identifying an assumption that is not bound to any scope.
  case unscoped

  /// A type identifying a non-linear, copyable assumption.
  case copyable

}

/// A set of type qualifiers.
public struct TypeQualifierSet: OptionSet {

  public let rawValue: Int

  /// A type identifying an assumption that is not bound to any scope.
  public static let unscoped = TypeQualifierSet(rawValue: 1 << 0)

  /// A type identifying a non-linear, copyable assumption.
  public static let copyable = TypeQualifierSet(rawValue: 1 << 1)

}
