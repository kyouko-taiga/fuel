import Basic

public protocol TypeSign: ASTNode {

  /// The semantic type represented by the signature.
  var type: QualType? { get }

}
