/// A built-in type.
public final class BuiltinType: BareType {

  /// Creates a new built-in type.
  init(name: String) {
    self.name = name
  }

  /// The type's declaration.
  public internal(set) weak var decl: BuiltinTypeDecl?

  /// The type's name.
  public let name: String

}

extension BuiltinType: Equatable {

  public static func == (lhs: BuiltinType, rhs: BuiltinType) -> Bool {
    return lhs === rhs
  }

}

extension BuiltinType: CustomStringConvertible {

  public var description: String {
    return name
  }

}
