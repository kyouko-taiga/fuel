/// A collection of top-level declarations (i.e., types and function).
///
/// A module (a.k.a. compilation unit) is an abstraction over one or several source files (a.k.a.
/// translation units), that forms a single object file. Modules can then be linked together to
/// create a single executable file or library.
public final class Module: Identifiable {

  public typealias ID = String

  /// Creates a new module.
  ///
  /// - Parameters:
  ///   - id: The module's identifier.
  ///   - typeDecls: The type declaratiosn of the module.
  ///   - funcDecls: The function declarations of the module.
  public init(id: ID, typeDecls: [NominalTypeDecl], funcDecls: [FuncDecl]) {
    self.id = id
    self.typeDecls = typeDecls
    self.funcDecls = funcDecls
  }

  /// The module's ID.
  public let id: ID

  /// The type declarations of the module.
  public var typeDecls: [NominalTypeDecl]

  /// The function declarations of the module.
  public var funcDecls: [FuncDecl]

  /// The built-in module.
  public static let builtin: Module = {
    let module = Module(id: "_Builtin", typeDecls: [], funcDecls: [])

    // Inject built-in type declarations.
    module.typeDecls.append(BuiltinTypeDecl(type: .void))
    module.typeDecls.append(BuiltinTypeDecl(type: .junk))
    module.typeDecls.append(BuiltinTypeDecl(type: .bool))
    module.typeDecls.append(BuiltinTypeDecl(type: .int))

    return module
  }()

}

extension Module: DeclContext {

  public var parent: DeclContext? { nil }

  public var decls: [NamedDecl] {
    return (typeDecls as [NamedDecl]) + (funcDecls as [NamedDecl])
  }

}

extension Module: CustomStringConvertible {

  public var description: String {
    return "Module(\(id))"
  }

}
