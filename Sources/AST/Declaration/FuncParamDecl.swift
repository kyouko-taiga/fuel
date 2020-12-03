import Basic

/// A function parameter declaration.
public final class FuncParamDecl: NamedDecl {

  public init(name: String) {
    self.name = name
  }

  /// The parameter's name.
  public var name: String

  /// The parameter's type.
  public var type: QualType?

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension FuncParamDecl: CustomStringConvertible {

  public var description: String {
    return name
  }

}
