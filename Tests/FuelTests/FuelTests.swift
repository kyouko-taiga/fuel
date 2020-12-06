import XCTest

import Basic
import Fuel

private let testsURL = URL(fileURLWithPath: #file)
  .deletingLastPathComponent()

class FuelTests: XCTestCase {

  let manager = FileManager.default

  func testSema() throws {
    guard let enumerator = manager.enumerator(
      at: testsURL.appendingPathComponent("Sema"),
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles])
    else {
      XCTFail("failed to open test folder")
      return
    }

    let sourceManager = SourceManager()

    for case let url as URL in enumerator where url.pathExtension == "fuel" {
      // Load the source file.
      guard let source = try? sourceManager.load(contentsOf: url) else {
        XCTFail("Failed to load '\(url)'")
        continue
      }

      // Scan the source file for test annotations.
      var expectations: [Int: [DiagnosticPattern]] = [:]

      let lines = source.contents.split(separator: "\n", omittingEmptySubsequences: false)
      for (i, line) in lines.enumerated() {
        guard let range = line.range(of: "#!error") else { continue }
        var start = line.index(range.lowerBound, offsetBy: 7)

        var offset: Int = 1
        if line[start...].starts(with: "@") {
          let end = line[start...].firstIndex(where: { $0.isWhitespace }) ?? line.endIndex
          offset += Int(line[line.index(after: start) ..< end]) ?? 0
          start = end
        }

        let message = line[start...].drop(while: { $0.isWhitespace })
        if message.isEmpty {
          expectations[i + offset, default: []].append(DiagnosticPattern(message: nil))
        } else {
          expectations[i + offset, default: []].append(DiagnosticPattern(message: String(message)))
        }
      }

      let checker = DiagnosticChecker(sourceManager: sourceManager, expectations: expectations)
      let driver = Driver(sourceManager: sourceManager, pipeline: [.parse(url), .runSema])
      driver.context.diagnosticConsumer = checker

      try driver.execute()

      if !checker.expectations.isEmpty {
        for (line, exp) in checker.expectations {
          for pattern in exp {
            let message = "Sema/\(url.lastPathComponent):\(line): "
              + "expected diagnostic was not raised: "
              + (pattern.message ?? "_")
            XCTFail(message)
          }
        }
      }
    }
  }

}
