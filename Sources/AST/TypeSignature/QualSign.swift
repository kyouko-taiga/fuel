import Basic

/// The signature of a qualified type.
public final class QualSign: TypeSign {

  public init(base: TypeSign, qualifiers: [TypeQual]) {
    self.base = base
    self.qualifiers = qualifiers
  }

  public var base: TypeSign

  public var qualifiers: [TypeQual]

  public var type: QualType?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension QualSign: CustomStringConvertible {

  public var description: String {
    var string = ""
    for qualifier in qualifiers {
      string += String(describing: qualifier) + " "
    }
    return string + String(describing: base)
  }

}
