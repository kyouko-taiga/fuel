/// The built-in polymorphic `Junk<>` type.
public final class JunkType: BareType {

  init(context: ASTContext, base: BareType) {
    self.base = base
    super.init(context: context)
  }

  override var bytes: [UInt8] {
    var bs: [UInt8] = []
    withUnsafeBytes(of: JunkType.self, { bs.append(contentsOf: $0) })
    withUnsafeBytes(of: base, { bs.append(contentsOf: $0) })
    return bs
  }

  /// A concrete type.
  public let base: BareType

}

extension JunkType: CustomStringConvertible {

  public var description: String {
    return "Junk<\(base)>"
  }

}
