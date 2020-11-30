/// A node which represents a declaration context scope (e.g., a function's body).
public protocol DeclContext: AnyObject {

  /// The scope enclosing this node, if any.
  var parent: DeclContext? { get }

  /// The declarations contained directly within the context.
  var decls: [NamedDecl] { get }

}
