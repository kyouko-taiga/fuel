import Foundation

import AST
import Basic
import Fuel

func main() throws {
  // Create a compilation driver.
  let driver = Driver()
  driver.astContext.diagnosticConsumer = Console(sourceManager: driver.sourceManager)

  // Configure the driver's pipeline.
  driver.pipeline.append(.parse(URL(fileURLWithPath: "Hello.fuel")))
  driver.pipeline.append(.runSema)

  // Execute the driver.
  try driver.execute()

  // Dump the compiled module.
  if let module = driver.module {
    let dumper = ASTDumper(output: FileOutputStream.stdout)
    dumper.visit(module)
  }
}

try main()
