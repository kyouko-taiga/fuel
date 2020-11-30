/// The signature of a qualified type.
public final class QualifiedSign: TypeSign {

  public init(base: TypeSign, qualifiers: [TypeQualifier]) {
    self.base = base
    self.qualifiers = qualifiers
  }

  public var base: TypeSign

  public var qualifiers: [TypeQualifier]

  public var type: TypeBase?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension QualifiedSign: CustomStringConvertible {

  public var description: String {
    var string = ""
    for qualifier in qualifiers {
      string += String(describing: qualifier) + " "
    }
    return string + String(describing: base)
  }

}

