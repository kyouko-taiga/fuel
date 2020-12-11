import LLVM
import AST

extension Expr {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    guard let emittable = self as? ValueEmittable else {
      fatalError("value is not emittable")
    }
    return emittable.emit(in: &cgContext)
  }

}

extension IdentExpr: ValueEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    return cgContext.environment[referredDecl!.symbol]!
  }

}

extension MemberExpr: ValueEmittable {

  /// Emits the access to a storage contained in an aggregate value.
  ///
  /// Member expressions can appear in two different situations. Either it refers to a value stored
  /// in memory, in which it's base expression should have a pointer type, or to a value loaded
  /// into a temporary, in which case it's base expression should **not** have a pointer type.
  ///
  /// This method assumes it is being used to handle the former case.
  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    // Split the member expression into a storage reference.
    let (baseExpr, path) = storageRef
    guard let identExpr = baseExpr as? IdentExpr else {
      preconditionFailure("Base expression should be an identifier")
    }

    let base = cgContext.environment[identExpr.referredDecl!.symbol]!
    if let ptrTy = base.type as? PointerType {
      // Access the storage with a GEP instruction.
      return cgContext.builder.buildInBoundsGEP(
        base,
        type: ptrTy.pointee,
        indices: ([0] + path).map({ cgContext.llvmInt32.constant($0) }))
    } else {
      fatalError("TODO: Emit extractvalue/insertvalue instructions")
    }
  }

}

extension BoolLit: ValueEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    return cgContext.llvmBool.constant(value ? 1 : 0)
  }

}

extension IntLit: ValueEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    return cgContext.llvmInt32.constant(value)
  }

}
