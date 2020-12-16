import AST
import Basic

public struct TypeError: Error {

  public let message: String

  public let range: SourceRange?

  public func report(in context: ASTContext) {
    context.report(message: message)
      .set(location: range?.lowerBound)
      .add(range: range)
  }

  static func undefinedExprType(expr: Expr) -> TypeError {
    return TypeError(
      message: "cannot determine the type of expression '\(expr)'",
      range: expr.range)
  }

  static func invalidTypeConversion(t1: QualType, t2: QualType, range: SourceRange?) -> TypeError {
    return TypeError(
      message: "cannot convert value of type '\(t1)' to expected type '\(t2)'",
      range: range)
  }

  static func invalidAssumptionConversion(
    a1: Assumption,
    a2: Assumption,
    range: SourceRange?
  ) -> TypeError {
    return TypeError(
      message:
        "cannot convert assumption ['\(a1.key): \(a1.value)'] " +
        "to expected assumption ['\(a2.key): \(a2.value)']",
      range: range)
  }

  static func inconsistentAssumption(assump: Assumption, range: SourceRange?) -> TypeError {
    return TypeError(
      message: "inconsistent assumption '[\(assump.key): \(assump.value)]'",
      range: range)
  }

  static func invalidLValue(expr: Expr) -> TypeError {
    return TypeError(
      message: "invalid l-value '\(expr)'",
      range: expr.range)
  }

  static func missingCapability(symbol: Symbol, type: QualType, range: SourceRange?) -> TypeError {
    return TypeError(
      message: "missing capability [\(symbol): \(type)]",
      range: range)
  }

  static func callToNonFunctionType(expr: Expr, type: BareType) -> TypeError {
    return TypeError(
      message: "call to non-function type '\(type)'",
      range: expr.range)
  }

  static func freeOnNonPointerType(expr: Expr, type: BareType) -> TypeError {
    return TypeError(
      message: "invalid free statement on non-pointer type '\(type)'",
      range: expr.range)
  }

  static func invalidCallArgTypes(funcIdent: IdentExpr, argTypes: [QualType?]) -> TypeError {
    let argTypesDesc = argTypes
      .map({ arg in arg.map(String.init(describing:)) ?? "_" })
      .joined(separator: ", ")

    return TypeError(
      message:"cannot call function '\(funcIdent)' with arguments list of type '\(argTypesDesc)'",
      range: funcIdent.range)
  }

  static func memberAccessInScalarType(expr: Expr, type: BareType) -> TypeError {
    return TypeError(
      message: "member access into non-tuple type '\(type)'",
      range: expr.range)
  }

  static func invalidMemberOffset(expr: Expr) -> TypeError {
    return TypeError(
      message: "invalid member offset",
      range: expr.range)
  }

}
