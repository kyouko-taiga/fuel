import LLVM
import AST

extension FuncDecl: ValueEmittable {

  func emit(in cgContext: inout CodeGenContext) -> IRValue {
    // Retrieve or create the LLVM function value.
    let llvmFunc = cgContext.function(decl: self)
    assert(llvmFunc.basicBlockCount == 0)

    guard let body = self.body else { return llvmFunc }

    // Set the name of each function argument.
    cgContext.environment = [:]

    let llvmParams = bareFuncType!.output.bareType.passingPolicy == .indirect
      ? llvmFunc.parameters[1...]
      : llvmFunc.parameters[0...]
    for (var llvmParam, fuelParam) in zip(llvmParams, params) {
      llvmParam.name = fuelParam.name
      cgContext.environment[fuelParam.symbol] = llvmParam
    }

    // Create the function's entry point.
    let entry = llvmFunc.appendBasicBlock(named: "entry", in: cgContext.llvmContext)
    cgContext.builder.positionAtEnd(of: entry)

    // Emit each statement.
    cgContext.currentFuncDecl = self
    for stmt in body {
      _ = stmt.emit(in: &cgContext)
    }

    return llvmFunc
  }

}
