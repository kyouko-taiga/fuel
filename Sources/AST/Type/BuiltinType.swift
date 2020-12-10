import Basic

/// A built-in type.
public final class BuiltinType: BareType {

  init(context: ASTContext, name: String) {
    self.name = name
    super.init(context: context)
  }

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
