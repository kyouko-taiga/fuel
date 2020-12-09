public final class BuiltinModule: Module {

  private init() {
    super.init(id: "_Builtin")

    // Create declarations for all built-in types.
    var builtinTypeDecls: [BuiltinTypeDecl] = []
    for type in types {
      let decl = BuiltinTypeDecl(type: type)
      decl.declContext = self
      builtinTypeDecls.append(decl)
    }

    // Create declarations for all built-in functions.
    var builtinFuncDecls: [FuncDecl] = []
    for type in integers {
      let decl = binaryOperation("add_\(type.name)", type.decl!)
      decl.declContext = self
      builtinFuncDecls.append(decl)
    }

    // Finalize the built-in module.
    typeDecls = builtinTypeDecls
    funcDecls = builtinFuncDecls
    stateGoals = [.namesResolved, .typeChecked, .typesResolved]
  }

  public static let instance = BuiltinModule()

  /// The built-in `Any` type.
  public let any = BuiltinType(name: "Any")

  /// The built-in `Void` type.
  public let void = BuiltinType(name: "Void")

  /// The built-in `Bool` type.
  public let bool = BuiltinType(name: "Bool")

  /// The built-in `Int32` type.
  public let int32 = BuiltinType(name: "Int32")

  /// The built-in `Int64` type.
  public let int64 = BuiltinType(name: "Int64")

  /// The declarations of all built-in integer types.
  public var integers: [BuiltinType] {
    return [int32, int64]
  }

  /// The declarations of all built-in types.
  public var types: [BuiltinType] {
    return [any, void, bool, int32, int64]
  }

  /// Creates a binary operation.
  ///
  /// Binary operations have type `(T, T) -> T`.
  private func binaryOperation(_ name: String, _ typeDecl: BuiltinTypeDecl) -> FuncDecl {
    return function(name, [typeDecl, typeDecl], typeDecl)
  }

  /// Creates a built-in function.
  private func function(
    _ name: String,
    _ inputs: [BuiltinTypeDecl],
    _ output: BuiltinTypeDecl
  ) -> FuncDecl {
    let inputSigns = inputs.enumerated().map({ (i: Int, input: BuiltinTypeDecl) -> IdentSign in
      let sign = IdentSign(name: input.name)
      sign.referredDecl = input
      sign.type = input.type!.qualified()
      return sign
    })

    let outputSign = IdentSign(name: output.name)
    outputSign.referredDecl = output
    outputSign.type = output.type!.qualified()

    let sign = FuncSign(params: inputSigns, output: outputSign)
    sign.type =
      FuncType(
        params: inputSigns.map({ $0.type! }),
        output: outputSign.type!)
      .qualified()

    let params = inputs.indices.map({ i in FuncParamDecl(name: "x\(i)") })
    let decl = FuncDecl(name: name, params: params, sign: sign, body: nil)

    for param in params {
      param.declContext = decl
    }

    return decl
  }

}
