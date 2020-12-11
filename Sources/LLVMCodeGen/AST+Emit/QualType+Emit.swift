import LLVM
import AST

extension QualType: TypeEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRType {
    return bareType.emit(in: &cgContext)
  }

}
