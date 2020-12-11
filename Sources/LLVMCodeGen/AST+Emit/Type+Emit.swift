import LLVM
import AST

extension BareType: TypeEmittable {

  /// The passing policy for this type at function boundaries.
  var passingPolicy: PassingPolicy {
    switch self {
    case let tupleTy as TupleType:
      return tupleTy.members.isEmpty
        ? .skipped
        : .indirect

    case let bundledTy as BundledType:
      return bundledTy.base.passingPolicy

    default:
      return .direct
    }
  }

  /// A passing policy.
  enum PassingPolicy {

    /// Values are ignored.
    ///
    /// This passing policy is used values that do not have any actual memory representation (e.g.,
    /// empty tuples).
    case skipped

    /// Values are passed directly as arguments or return values.
    case direct

    /// Values are passed indirectly, as pointers.
    ///
    /// On return values, this policy specifies that the return type will appear as a pointer, at
    /// the first position of the parameter list.
    case indirect

  }

  func emit(in cgContext: inout CodeGenContext) -> IRType {
    switch self {
    case context.builtin.any   : return cgContext.llvmAny
    case context.builtin.void  : return cgContext.llvmVoid
    case context.builtin.bool  : return cgContext.llvmBool
    case context.builtin.int32 : return cgContext.llvmInt32
    case context.builtin.int64 : return cgContext.llvmInt64

    case let tupleTy as TupleType:
      return StructType(elementTypes: tupleTy.members.map({ $0.emit(in: &cgContext) }))

    case let funcTy as FuncType:
      var llvmParamTys = funcTy.params.compactMap({ (qualTy) -> IRType? in
        let llvmTy = qualTy.emit(in: &cgContext)

        switch qualTy.bareType.passingPolicy {
        case .skipped : return nil
        case .direct  : return llvmTy
        case .indirect: return PointerType(pointee: llvmTy)
        }
      })

      var llvmReturnTy = funcTy.output.emit(in: &cgContext)

      switch funcTy.output.bareType.passingPolicy {
      case .skipped:
        llvmReturnTy = cgContext.llvmVoid

      case .indirect:
        llvmParamTys.insert(PointerType(pointee: llvmReturnTy), at: 0)
        llvmReturnTy = cgContext.llvmVoid

      case .direct:
        break
      }

      return FunctionType(llvmParamTys, llvmReturnTy)

    default:
      fatalError("unresolvable type '\(self)'")
    }
  }

}
