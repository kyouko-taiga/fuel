import LLVM

extension IRBuilder {

  func buildAllocaInEntry(
    of function: Function,
    type: IRType,
    count: IRValue? = nil,
    alignment: Alignment = .zero,
    name: String = ""
  ) -> IRInstruction {
    guard let entry = function.entryBlock else {
      return buildAlloca(type: type, count: count, alignment: alignment, name: name)
    }

    let current = insertBlock
    if let inst = entry.instructions.first(where: { !$0.isAAllocaInst }) {
      positionBefore(inst)
    } else {
      positionAtEnd(of: entry)
    }

    let alloca = buildAlloca(type: type, count: count, alignment: alignment, name: name)

    if let block = current {
      positionAtEnd(of: block)
    }
    return alloca
  }

}
