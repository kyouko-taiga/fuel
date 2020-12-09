import Basic

/// A function declaration.
public final class FuncDecl: NamedDecl, DeclContext {

  /// Creates a new function declaration.
  ///
  /// - Parameters:
  ///   - name: The function's name.
  ///   - params: The function's parameters.
  ///   - sign: The signature of the function's type.
  ///   - body: The function's body.
  public init(name: String, params: [FuncParamDecl], sign: TypeSign, body: BraceStmt?) {
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
  public var body: BraceStmt?

  /// The function's semantic type.
  public var type: QualType?

  public var parent: DeclContext?

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

  public func decls(named name: String) -> AnySequence<NamedDecl> {
    return AnySequence(params.filter({ $0.name == name }))
  }

  public func firstDecl(named name: String) -> NamedDecl? {
    return params.first(where: { $0.name == name })
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
