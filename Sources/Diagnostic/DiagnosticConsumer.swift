import Basic

public protocol DiagnosticConsumer {

  func consume(_ diagnostic: Diagnostic)

  func consume(_ diagnostic: Diagnostic, at location: SourceLocation)

}
