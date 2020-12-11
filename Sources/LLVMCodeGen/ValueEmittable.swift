import LLVM
import AST

protocol ValueEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRValue

}
