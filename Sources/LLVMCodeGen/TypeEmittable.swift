import LLVM
import AST

protocol TypeEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRType

}
