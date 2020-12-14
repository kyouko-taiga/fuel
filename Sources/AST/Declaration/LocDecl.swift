import Basic

/// The declaration of a cell location.
public final class LocDecl: NamedDecl {

  public init(name: String) {
    self.name = name
  }

  public var name: String

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

  public var symbol: Symbol { Symbol(decl: self, isLocRef: true) }

}

extension LocDecl: CustomStringConvertible {

  public var description: String {
    return name
  }

}
