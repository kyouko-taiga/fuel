/// A function declaration.
public final class FuncDecl: NamedDecl, DeclContext {

  /// Creates a new function declaration.
  ///
  /// - Parameters:
  ///   - name: The function's name.
  ///   - params: The function's parameters.
  ///   - sign: The signature of the function's type.
  ///   - body: The function's body.
  public init(name: String, params: [FuncParamDecl], sign: TypeSign, body: Block?) {
    self.name = name
    self.params = params
    self.sign = sign
    self.body = body
  }

  /// The function's name.
  public var name: String

  /// The function's parameters.
  public var params: [FuncParamDecl]

  /// The signature of the function's type.
  public var sign: TypeSign

  /// The function's body.
  public var body: Block?

  /// The function's semantic type.
  public var type: TypeBase?

  public var parent: DeclContext?

  public var decls: [NamedDecl] { params as [NamedDecl] }

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension FuncDecl: CustomStringConvertible {

  public var description: String {
    let paramNames = params.map({ $0.name }).joined(separator: ", ")
    if let body = self.body {
      return "func \(name)(\(paramNames)) : \(sign) \(body)"
    } else {
      return "func \(name)(\(paramNames)) : \(sign)"
    }
  }

}

extension FuncDecl: CustomDebugStringConvertible {

  public var debugDescription: String {
    return "FuncDecl(\(name))"
  }

}
