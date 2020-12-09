/// A node which represents a declaration context scope (e.g., a function's body).
public protocol DeclContext: AnyObject {

  /// The scope enclosing this node, if any.
  var parent: DeclContext? { get }

  /// Returns the declarations named after the specified name.
  ///
  /// - Parameter name: The name of the declarations to search.
  func decls(named name: String) -> AnySequence<NamedDecl>

  /// Returns the first declaration named after the specified name.
  ///
  /// - Parameter name: The name of the declaration to search.
  func firstDecl(named name: String) -> NamedDecl?

}

extension DeclContext {

  public func firstDecl(named name: String) -> NamedDecl? {
    let it = decls(named: name).makeIterator()
    return it.next()
  }

}
