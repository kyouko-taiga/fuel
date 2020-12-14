/// A symbol that can occur in the domain of a typing context.
///
/// Symbols are used to uniquely identify a named entity. They satisfy the following properties:
/// * Two symbols referring to the same declaration are equal.
/// * Two symbols referring to different declarations are different, even if those declarations
///   have the same name and live in the same declaration context.
///
/// A symbol created for a specific declaration (i.e., using `init(decl:isLocRef:)`) is only valid
/// for the duration of the declaration's lifetime. Other symbols are called *anonymous*. Anonymous
/// symbols are always valid.
public struct Symbol {

  /// Creates a symbol referring to the given declaration.
  ///
  /// - Parameters:
  ///   - decl: A named declaration.
  ///   - isLocRef: A Boolean value indicating whether the symbol refers to a memory location.
  public init(decl: NamedDecl, isLocRef: Bool = false) {
    // Make sure we can use at least two bits for pointer tagging.
    assert(MemoryLayout<UnsafeRawPointer>.alignment >= 2)

    var value = Int(bitPattern: Unmanaged.passUnretained(decl as AnyObject).toOpaque())
    value |= 0b01
    if isLocRef {
      value |= 0b10
    }

    self.rawValue = value
  }

  /// Creates an anonymous symbol from an identifier.
  ///
  /// - Parameters:
  ///   - id: A unique symbol identifier.
  ///   - isReferringToLocation: A Boolean value indicating whether the symbol is meant to refer to
  ///     a memory location.
  public init(id: Int, isLocRef: Bool) {
    self.rawValue = isLocRef
      ? (id << 2) | 0b10
      : (id << 2)
  }

  /// The symbol's raw value.
  public let rawValue: Int

  /// The declaration to which this symbol refers.
  public var decl: NamedDecl? {
    guard (rawValue & 0b01) == 0b01 else { return nil }

    let ptr = UnsafeRawPointer(bitPattern: rawValue & ~0b11)!
    return (Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue() as! NamedDecl)
  }

  /// The symbol's name.
  public var name: String? {
    return decl?.name
  }

  /// A value indicating whether the symbol refers to a memory location.
  public var isLocRef: Bool {
    return (rawValue & 0b10) == 0b10
  }

}

extension Symbol: Hashable {
}

extension Symbol: Comparable {

  public static func < (lhs: Symbol, rhs: Symbol) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }

}

extension Symbol: CustomStringConvertible {

  public var description: String {
    if let name = self.name {
      return name
    } else {
      let id = String(rawValue & ~0b11, radix: 16, uppercase: false)
      return "#\(id)"
    }
  }

}
