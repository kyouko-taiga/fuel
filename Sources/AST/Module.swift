import Basic

/// A collection of top-level declarations (i.e., types and function).
///
/// A module (a.k.a. compilation unit) is an abstraction over one or several source files (a.k.a.
/// translation units), that forms a single object file. Modules can then be linked together to
/// create a single executable file or library.
public class Module: Identifiable {

  public typealias ID = String

  /// Creates a new module.
  ///
  /// - Parameters:
  ///   - id: The module's identifier.
  ///   - typeDecls: The type declaratiosn of the module.
  ///   - funcDecls: The function declarations of the module.
  public init(
    id: ID,
    context: ASTContext,
    typeDecls: [String: NominalTypeDecl] = [:],
    funcDecls: [String: FuncDecl] = [:]
  ) {
    self.id = id
    self.context = context
    self.typeDecls = typeDecls
    self.funcDecls = funcDecls
  }

  /// The module's ID.
  public final let id: ID

  /// The AST context owning the module.
  public unowned let context: ASTContext

  /// The type declarations of the module.
  public internal(set) var typeDecls: [String: NominalTypeDecl]

  /// Merges the given type declarations into the module.
  ///
  /// - Parameter newDecls: A sequence of declarations. Every declaration with duplicate name is
  ///   silently skipped.
  public func merge<S>(typeDecls newDecls: S) where S: Sequence, S.Element: NominalTypeDecl {
    for decl in newDecls {
      guard funcDecls[decl.name] == nil else { continue }
      typeDecls[decl.name] = decl
    }
  }

  /// The function declarations of the module.
  public internal(set) var funcDecls: [String: FuncDecl]

  /// Merges the given function declarations into the module.
  ///
  /// - Parameter newDecls: A sequence of declarations. Every declaration with duplicate name is
  ///   silently skipped.
  public func merge<S>(funcDecls newDecls: S) where S: Sequence, S.Element == FuncDecl {
    for decl in newDecls {
      guard funcDecls[decl.name] == nil else { continue }
      funcDecls[decl.name] = decl
    }

    stateGoals.removeAll()
  }

  /// All top-level declarations in the module.
  public var allDecls: AnySequence<NamedDecl> {
    let tit = typeDecls.values.makeIterator().map({ $0 as NamedDecl })
    let fit = funcDecls.values.makeIterator().map({ $0 as NamedDecl })
    return AnySequence({ tit.concatenated(with: fit) })
  }

  /// Indicates compilation state of the module.
  ///
  /// This property is meant to be used internally. It is reset every time the module's contents
  /// change, and updated at the end of every stage of compilation.
  public final var stateGoals: Set<StateGoal> = []

  public enum StateGoal {

    /// All names have been properly resolved.
    case namesResolved

    /// All types have been properly resolved.
    case typesResolved

    /// All declarations have been properly type-checked.
    case typeChecked

  }

}

extension Module: DeclContext {

  public final var parent: DeclContext? { nil }

  public final func decls(named name: String) -> AnySequence<NamedDecl> {
    var results: [NamedDecl] = []
    if let decl = typeDecls[name] {
      results.append(decl)
    }
    if let decl = funcDecls[name] {
      results.append(decl)
    }
    return AnySequence(results)
  }

  public final func firstDecl(named name: String) -> NamedDecl? {
    return typeDecls[name] ?? funcDecls[name]
  }

}

extension Module: CustomStringConvertible {

  public final var description: String {
    return "Module(\(id))"
  }

}
