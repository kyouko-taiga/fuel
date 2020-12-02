import XCTest
import Fuel

fileprivate let testsURL = URL(fileURLWithPath: #file)
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

    let srcManager = try SourceManager()

    for case let url as URL in enumerator where url.pathExtension == "fuel" {
      // Load the source file.
      guard let source = try? srcManager.load(contentsOf: url) else {
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

      let checker = DiagnosticChecker(sourceManager: srcManager, expectations: expectations)
      let context = CompilerContext()
      context.diagnosticConsumer = checker

      let driver = Driver(
        sourceManager: srcManager,
        pipeline: [.parse(url), .runSema],
        context: context)
      try driver.execute()
      XCTAssert(
        checker.expectations.isEmpty,
        "Expected error was not raised while processing '\(url.lastPathComponent)'")
    }
  }

}
