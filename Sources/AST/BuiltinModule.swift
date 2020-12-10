public final class BuiltinModule: Module {

  init(context: ASTContext) {
    // Create the built-in types.
    any   = BuiltinType(context: context, name: "Any")
    void  = BuiltinType(context: context, name: "Void")
    bool  = BuiltinType(context: context, name: "Bool")
    int32 = BuiltinType(context: context, name: "Int32")
    int64 = BuiltinType(context: context, name: "Int64")

    super.init(id: "_Builtin", context: context, typeDecls: [
      "Any"   : BuiltinTypeDecl(type: any),
      "Void"  : BuiltinTypeDecl(type: void),
      "Bool"  : BuiltinTypeDecl(type: bool),
      "Int32" : BuiltinTypeDecl(type: int32),
      "Int64" : BuiltinTypeDecl(type: int64),
    ])

    // Create the built-in functions.
    var builtinFuncDecls: [FuncDecl] = []

    for type in integers {
      let decl = binaryOperation(
        "add_\(type.name)",
        typeDecls[type.name] as! BuiltinTypeDecl)
      decl.declContext = self
      builtinFuncDecls.append(decl)
    }

    // Mark the module as type-checked.
    stateGoals = [.namesResolved, .typeChecked, .typesResolved]
  }

  /// The built-in `Any` type.
  public let any  : BuiltinType

  /// The built-in `Void` type.
  public let void : BuiltinType

  /// The built-in `Bool` type.
  public let bool : BuiltinType

  /// The built-in `Int32` type.
  public let int32: BuiltinType

  /// The built-in `Int64` type.
  public let int64: BuiltinType

  /// The declarations of all built-in integer types.
  public var integers: [BuiltinType] {
    return [int32, int64]
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
      sign.type = (input.type as! BuiltinType).qualified()
      return sign
    })

    let outputSign = IdentSign(name: output.name)
    outputSign.referredDecl = output
    outputSign.type = (output.type as! BuiltinType).qualified()

    let sign = FuncSign(params: inputSigns, output: outputSign)
    sign.type =
      context.funcType(
        params: inputSigns.map({ $0.type! }),
        output: outputSign.type!)
      .qualified()

    let params = inputs.indices.map({ i in FuncParamDecl(name: "x\(i)") })
    let decl = FuncDecl(name: name, params: params, sign: sign, body: nil)
    decl.type = sign.type

    for param in params {
      param.declContext = decl
    }

    return decl
  }

}
