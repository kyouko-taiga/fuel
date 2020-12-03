import Basic

/// A type signature packed with assumptions about the typing environment.
public final class PackedSign: TypeSign {

  public init(base: TypeSign, assumptions: [AssumptionSign]) {
    self.base = base
    self.assumptions = assumptions
  }

  public var base: TypeSign

  public var assumptions: [AssumptionSign]

  public var type: QualType?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension PackedSign: CustomStringConvertible {

  public var description: String {
    guard !assumptions.isEmpty
      else { return String(describing: base) }

    let tail = assumptions.map(String.init(describing:)).joined(separator: " + ")

    switch base {
    case is FuncSign, is UniversalSign:
      return "(\(base)) + \(tail)"
    default:
      return "\(base) + \(tail)"
    }
  }

}
