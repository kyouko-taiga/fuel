/// A built-in type.
public final class BuiltinType: BareType {

  private init(name: String) {
    self.name = name
  }

  /// The type's name.
  public let name: String

  /// The built-in `Void` type.
  public static let void = BuiltinType(name: "Void")

  /// The built-in `Junk` type.
  public static let junk = BuiltinType(name: "Junk")

  /// The built-in `Bool` type.
  public static let bool = BuiltinType(name: "Bool")

  /// The built-in `Int` type.
  public static let int = BuiltinType(name: "Int")

}

extension BuiltinType: CustomStringConvertible {

  public var description: String {
    return name
  }

}
