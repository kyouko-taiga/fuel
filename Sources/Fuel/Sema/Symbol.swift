/// A symbol that can occur in the domain of a typing context.
///
/// Symbols uniquely identify an identifier in a given declaration context. They satisfy the
/// following properties:
/// * Two symbols referring to the same declaration are equal.
/// * Two symbols referring to different declarations are different, even if those declarations
///   have the same name.
public struct Symbol {

  /// Creates a symbol referring to the given declaration.
  public init(decl: NamedDecl) {
    self.decl = decl

    // FIXME: Use more reliable identifiers
    // Using the declaration's object identifier is not safe, as there is no guarantee that this
    // identity cannot be reused for another declaration, while the symbol is still around.
    id = Int(bitPattern: ObjectIdentifier(decl)) >> 2
  }

  /// Creates a new symbol from an identifier.
  ///
  /// - Parameters:
  ///   - id: A symbol identifier.
  ///   - isReferringToLocation: A Boolean value indicating whether the symbol is meant to refer to
  ///     a memory location.
  init(id: Int, isReferringToLocation: Bool) {
    // Set the MSB at 1 so that the ID cannot clash with an object identifier.
    var identifier = id | (0b1 << (Int.bitWidth - 1))
    if isReferringToLocation {
      identifier |= (0b1 << (Int.bitWidth - 2))
    }

    self.id = identifier
  }

  /// The symbol's unique identifier.
  public let id: Int

  /// The declaration to which this symbol refers.
  public weak private(set) var decl: NamedDecl?

  /// The symbol's name.
  public var name: String? {
    return decl?.name
  }

  /// A value indicating whether the symbol refers to a memory location.
  var isReferringToLocation: Bool {
    return self.id & (0b1 << (Int.bitWidth - 2)) != 0
  }

}

extension Symbol: Hashable {

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: Symbol, rhs: Symbol) -> Bool {
    return lhs.id == rhs.id
  }

}

extension Symbol: CustomStringConvertible {

  public var description: String {
    let addr = String((id << 2) >> 2, radix: 16, uppercase: false)
    if let name = self.name {
      return "\(name)#\(addr)"
    } else {
      return "#\(addr)"
    }
  }

}

extension NamedDecl {

  /// The symbol identifying this declaration.
  var symbol: Symbol {
    return Symbol(decl: self)
  }

}
