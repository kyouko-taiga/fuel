/// A symbol substitution table, used to infer universal type instantiation parameters.
///
/// This type is essentially a thin wrapper around a native dictionary that provides helper to
/// support unification.
struct SubstitutionTable {

  init(_ substitutions: [Symbol: Symbol] = [:]) {
    self.substitutions = substitutions
  }

  /// The substitutions in the table.
  var substitutions: [Symbol: Symbol]

//  /// Returns the symbol for which the given symbol must be substituted.
//  func value(for type: TypeBase) -> TypeBase {
//    guard let variable = type as? TypeVar else {
//      return type
//    }
//
//    var walked = substitutions[variable]
//    while let subst = walked as? TypeVar {
//      walked = substitutions[subst]
//    }
//    return walked ?? type
//  }
//
//  /// Set the type by which the given variable must be substituted.
//  mutating func set(_ type: TypeBase, for variable: TypeVar) {
//    var walked = variable
//    while let subst = substitutions[walked] {
//      guard let tv = subst as? TypeVar else {
//        fatalError("inconsistent susbtitution")
//      }
//      walked = tv
//    }
//
//    substitutions[walked] = type
//  }

}

extension SubstitutionTable: CustomStringConvertible {

  var description: String {
    return String(describing: substitutions)
  }

}
