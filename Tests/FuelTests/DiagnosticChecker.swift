import XCTest
import Fuel

class DiagnosticChecker: DiagnosticConsumer {

  init(sourceManager: SourceManager, expectations: [Int: [DiagnosticPattern]]) {
    self.sourceManager = sourceManager
    self.expectations = expectations
  }

  /// A source manager.
  var sourceManager: SourceManager

  /// The diagnostics that are expected to be received.
  var expectations: [Int: [DiagnosticPattern]]

  func consume(_ diagnostic: Diagnostic) {
    XCTFail("Unexpected diagnostic: \(diagnostic.message)")
  }

  func consume(_ diagnostic: Diagnostic, at location: SourceLocation) {
    // Load the contents of the source file.
    guard let source = try? sourceManager.load(contentsOf: location.sourceURL) else {
      consume(diagnostic)
      return
    }

    let (lineIndex, _) = source.caretPosition(at: location)
    let exp = expectations[lineIndex] ?? []
    guard let i = exp.firstIndex(where: { $0.matches(diagnostic) }) else {
      XCTFail("Unexpected diagnostic: \(diagnostic.message)")
      return
    }

    if exp.count > 1 {
      expectations[lineIndex]?.remove(at: i)
    } else {
      expectations[lineIndex] = nil
    }
  }

}

struct DiagnosticPattern {

  var message: String?

  func matches(_ diagnostic: Diagnostic) -> Bool {
    if let message = self.message {
      return message == diagnostic.message
    } else {
      return true
    }
  }

}
