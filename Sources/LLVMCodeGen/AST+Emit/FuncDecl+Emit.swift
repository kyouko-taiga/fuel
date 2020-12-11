import LLVM
import AST

extension FuncDecl: ValueEmittable {

  func emit(in context: inout CodeGenContext) -> IRValue {
    // Retrieve or create the LLVM function value.
    let llvmFunc = context.function(decl: self)
    assert(llvmFunc.basicBlockCount == 0)

    guard let body = self.body else { return llvmFunc }

    // Set the name of each function argument.
    context.environment = [:]

    let llvmParams = bareFuncType!.output.bareType.passingPolicy == .indirect
      ? llvmFunc.parameters[1...]
      : llvmFunc.parameters[0...]
    for (var llvmParam, fuelParam) in zip(llvmParams, params) {
      llvmParam.name = fuelParam.name
      context.environment[fuelParam.symbol] = llvmParam
    }

    // Create the function's entry point.
    let entry = llvmFunc.appendBasicBlock(named: "entry")
    context.builder.positionAtEnd(of: entry)

    // Emit each statement.
    context.currentFuncDecl = self
    for stmt in body {
      _ = (stmt as? ValueEmittable)?.emit(in: &context)
    }

    return llvmFunc
  }

}
