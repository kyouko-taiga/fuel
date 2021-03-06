/// A type assumption.
public typealias Assumption = (key: Symbol, value: QualType)

/// A set of type assumptions.
public typealias TypingContext = [Symbol: QualType]

extension TypingContext {

  static func + (lhs: TypingContext, rhs: TypingContext) -> TypingContext {
    precondition(Set(lhs.keys).isDisjoint(with: rhs.keys))
    var new = lhs
    for (key, value) in rhs {
      new[key] = value
    }
    return new
  }

}
