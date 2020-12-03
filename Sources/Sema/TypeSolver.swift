import AST

/// A helper object that gathers the logic involced in type-checking function calls.
///
/// Since function signatures may be universally quantified over memory locations, type-checking a
/// call requires to instantiate each location first. Assuming the call is well-typed, each pair of
/// argument/parameter constitutes a typing constraint, potentially involving quantified locations.
/// By solving these constraints, we can create a substitution table that maps abstract locations
/// onto concrete ones, occurring in the typing context.
///
/// This process is necessarily recursive, as generic locations can be nested arbitrarily within
/// packed types (e.g., `∀ a, b . (!a + [a: !b] + [b: τ]) -> Void`).
struct TypeSolver {

  /// The typing context in which the constraints should be solved.
  let context: TypingContext

  /// The set of constraints to solve.
  var constraints: [Constraint]

  /// The set of universally quantified memory locations. These are the names of the "generic"
  /// locations that should be instantiated with concrete ones, occurring in the typing context.
  let quantifiedParams: [QuantifiedParam]

  /// A dictionary mapping universally quantified (i.e., "generic") locations onto concrete
  /// locations occurring in the typing context.
  var substitutions: [Symbol: Symbol] = [:]

  func substitution(for symbol: Symbol) -> Symbol {
    var walked = symbol
    while let s = substitutions[walked] {
      walked = s
    }
    return walked
  }

  func decode(_ operand: ConstraintOperand) -> QualType? {
    switch operand {
    case .type(let tau):
      return tau

    case .ref(let symbol):
      if let tau = context[substitution(for: symbol)] {
        return tau
      } else {
        return nil
      }
    }
  }

  /// Solves the typing constraints.
  ///
  /// - Returns: The set of assumptions associated with the right operand of each constraint if
  ///   they could be solved; otherwise `nil`.
  mutating func solve() -> [Assumption]? {
    var assumptions: [Assumption] = []

    while let constraint = constraints.popLast() {
      // Decode type operands.
      guard var lhs = decode(constraint.lhs),
            var rhs = decode(constraint.rhs)
      else {
        // FIXME: Break infinite loops.
        constraints.insert(constraint, at: 0)
        continue
      }

      // Move on to the next constraint if types are trivially equal, as their unification will not
      // result in any additional information.
      if lhs == rhs {
        continue
      }

      // Unpack types if necessary.
      if let (tau, eta) = lhs.unpacked {
        lhs = tau
        constraints.append(
          contentsOf: eta.map({ Constraint(lhs: .ref($0.key), rhs: .type($0.value)) }))
      }
      if let (tau, eta) = rhs.unpacked {
        rhs = tau
        assumptions.append(contentsOf: eta)
        constraints.append(
          contentsOf: eta.map({ Constraint(lhs: .ref($0.key), rhs: .type($0.value)) }))
      }

      // Unify the types, effectively solving the constraint.
      guard unify(lhs, rhs) else {
        return nil
      }
    }

    for key in substitutions.keys {
      let walked = substitution(for: key)
      if walked != key {
        substitutions[key] = walked
      }
    }

    return assumptions.map({ (key, value) in
      (substitutions[key] ?? key, value.substituting(substitutions))
    })
  }

  mutating func unify(_ lhs: QualType, _ rhs: QualType) -> Bool {
    if lhs <= rhs {
      return true
    }

    if let a = lhs.bareType as? LocationType,
       let b = rhs.bareType as? LocationType,
       quantifiedParams.contains(b.location.name ?? "")
    {
      assert(!substitutions.keys.contains(b.location))
      substitutions[b.location] = a.location

      return lhs <= QualType(bareType: a, quals: rhs.quals)
    }

    return false
  }

  /// A constraint between two type expressions.
  struct Constraint {

    let lhs: ConstraintOperand

    let rhs: ConstraintOperand

  }

  /// The expression of a type in a constraint.
  enum ConstraintOperand {

    case type(QualType)

    case ref(Symbol)

  }

}
