public final class BuiltinModule: Module {

  init(context: ASTContext) {
    // Create the built-in types.
    any   = BuiltinType(context: context, name: "Any")
    void  = BuiltinType(context: context, name: "Void")
    bool  = BuiltinType(context: context, name: "Bool")
    int32 = BuiltinType(context: context, name: "Int32")
    int64 = BuiltinType(context: context, name: "Int64")

    // Initialize the built-in module.
    super.init(id: "_Builtin", context: context)

    // Create the built-in type declarations.
    typeDecls = [
      "Any"   : BuiltinTypeDecl(type: any),
      "Void"  : BuiltinTypeDecl(type: void),
      "Bool"  : BuiltinTypeDecl(type: bool),
      "Int32" : BuiltinTypeDecl(type: int32),
      "Int64" : BuiltinTypeDecl(type: int64),
    ]

    // Create the built-in function declarations.
    for type in integers {
      let intDecl = typeDecls[type.name] as! BuiltinTypeDecl

      for binary in ["add_", "sub_", "mul_", "div_"] {
        let funcDecl = binaryOperation(binary + (type.name), intDecl)
        funcDecls[funcDecl.name] = funcDecl
      }

      for predicate in ["eq_", "ne_", "gt_", "ge_", "lt_", "le_"] {
        let funcDecl = predicateOperation(predicate + (type.name), intDecl)
        funcDecls[funcDecl.name] = funcDecl
      }
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

  /// Creates the declaration of a binary operation.
  ///
  /// Binary operations have type `(T, T) -> T`.
  private func binaryOperation(_ name: String, _ typeDecl: BuiltinTypeDecl) -> FuncDecl {
    return function(name, [typeDecl, typeDecl], typeDecl)
  }

  /// Creates the declaration of a predicate operation.
  ///
  /// Predicate operations have type `(T, T) -> Bool`.
  private func predicateOperation(_ name: String, _ typeDecl: BuiltinTypeDecl) -> FuncDecl {
    let boolDecl = typeDecls["Bool"] as! BuiltinTypeDecl
    return function(name, [typeDecl, typeDecl], boolDecl)
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

    decl.declContext = self
    return decl
  }

}
