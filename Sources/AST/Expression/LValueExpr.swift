/// An expression identifying a storage location.
public protocol LValueExpr: Expr {

  var storageRef: (base: Expr, path: [Int]) { get }

}
