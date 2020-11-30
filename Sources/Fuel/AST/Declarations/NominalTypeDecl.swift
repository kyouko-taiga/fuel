/// The declaration of a nominal type.
public protocol NominalTypeDecl: NamedDecl {

  /// The semantic type represented by the declaration.
  var type: TypeBase? { get }

}
