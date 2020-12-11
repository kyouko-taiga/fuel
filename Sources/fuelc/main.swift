import Foundation

import AST
import Basic
import Fuel

func main() throws {
  // Create a compilation driver.
  let driver = Driver(moduleID: "main")
  driver.astContext.diagnosticConsumer = Console(sourceManager: driver.sourceManager)

  // Configure the driver's pipeline.
  driver.pipeline.append(.parse(URL(fileURLWithPath: "Hello.fuel")))
  driver.pipeline.append(.runSema)
  driver.pipeline.append(.emitLLVM)

  // Execute the driver.
  try driver.execute()

  // Dump the compiled module.
  if CommandLine.arguments.contains("--dump-ast") {
    let fos = FileOutputStream.stdout
    let dumper = ASTDumper(output: fos)
    dumper.visit(driver.module)
    fos.write("\n")
  }
}

try main()
