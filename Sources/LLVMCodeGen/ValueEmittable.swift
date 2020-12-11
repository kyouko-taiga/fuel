import LLVM
import AST

protocol ValueEmittable {

  func emit(in context: inout CodeGenContext) -> IRValue

}
