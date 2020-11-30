public final class FuncSign: TypeSign {

  public init(params: [TypeSign], output: TypeSign) {
    self.params = params
    self.output = output
  }

  /// The signature of the function's input parameters.
  public var params: [TypeSign]

  /// The signature of the function's output.
  public var output: TypeSign

  public var type: TypeBase?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension FuncSign: CustomStringConvertible {

  public var description: String {
    let dom = params.map(String.init(describing:)).joined(separator: ", ")
    let codom: String
    switch output {
    case is FuncSign, is UniversalSign:
      codom = "(\(output))"
    default:
      codom = String(describing: output)
    }

    return "(\(dom)) -> \(codom)"
  }

}
