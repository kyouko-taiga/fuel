/// An ill-formed type.
///
/// This class is used internally during semantic analysis to represent a type failure.
public final class ErrorType: BareType {

  private override init() {
  }

  public static let get = ErrorType()

}
