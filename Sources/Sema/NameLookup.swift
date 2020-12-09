import AST

/// This file implements most of the code involved in name lookups as extensions on AST nodes.
///
/// Name lookups are performed by walking declaration contexts and searching for the appropriate
/// named declarations. Contexts are walked outward from an innermost "base" context until either
/// the looked up declaration is found, or the top-level built-in context has been reached.

extension DeclContext {

  /// Searches for a declaration that matches the given name from this context.
  ///
  /// - Parameter name: The name to look up.
  func lookup(name: String) -> NamedDecl? {
    var declContext: DeclContext = self
    while true {
      // Search for a match in the current context.
      if let match = declContext.firstDecl(named: name) {
        // Return the the first match we find. Note that there shouldn't be more than one single
        // match, as symbols can't be overloaded.
        return match
      } else if let parent = declContext.parent {
        // Move to the parent context.
        declContext = parent
      } else if declContext !== BuiltinModule.instance {
        // Move to the built-in context.
        declContext = BuiltinModule.instance
      } else {
        // We reached the top-level built-in context; the lookup failed.
        return nil
      }
    }
  }

}
