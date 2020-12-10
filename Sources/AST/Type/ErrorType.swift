/// An ill-formed type.
///
/// This class is used internally during semantic analysis to represent a type failure. It should
/// not survive beyond a successul type-checking pass.
public final class ErrorType: BareType {
}
