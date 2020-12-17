import XCTest

import Basic
import Diagnostic
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
    XCTFail("unexpected diagnostic: \(diagnostic.message)")
  }

  func consume(_ diagnostic: Diagnostic, at location: SourceRange.Bound) {
    // Load the contents of the source file.
    guard let source = sourceManager.source(containing: location) else {
      consume(diagnostic)
      return
    }

    let lineIndex = source.lineIndex(at: location)
    let exp = expectations[lineIndex] ?? []
    guard let i = exp.firstIndex(where: { $0.matches(diagnostic) }) else {
      // TODO: Include line and column index in the failure message.
      let filename = source.url.lastPathComponent
      XCTFail("\(filename): unexpected diagnostic: \(diagnostic.message)")
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
