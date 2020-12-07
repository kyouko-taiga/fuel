/// The built-in polymorphic `Junk<>` type.
public final class JunkType: BareType {

  public init(base: BareType) {
    self.base = base
  }

  /// A concrete type.
  public let base: BareType

}
