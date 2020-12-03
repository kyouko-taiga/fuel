import Foundation

import Basic
import Fuel

func main() throws {
  // Create a source manager.
  let sourceManager = try SourceManager()

  // Create a compilation driver.
  let driver = Driver(sourceManager: sourceManager)
  driver.context.diagnosticConsumer = Console(sourceManager: sourceManager)

  // Configure the driver's pipeline.
  driver.pipeline.append(.parse(URL(fileURLWithPath: "Hello.fuel")))
  driver.pipeline.append(.runSema)

  // Execute the driver.
  try driver.execute()

  // Dump the compiled module.
  if let module = driver.module {
    print(module)
  }
}

try main()
