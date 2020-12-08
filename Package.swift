// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "Fuel",
  platforms: [
    .macOS(.v10_14)
  ],
  products: [
    .executable(name: "fuelc", targets: ["fuelc"]),
    .library(name: "Fuel", targets: ["Fuel"]),
  ],
  dependencies: [
    .package(name: "LLVM", url: "https://github.com/llvm-swift/LLVMSwift.git", from: "0.7.0"),
  ],
  targets: [
    .target(name: "fuelc", dependencies: ["Fuel", "Diagnostic"]),
    .target(
      name: "Fuel",
      dependencies: ["AST", "Basic", "Lexer", "LLVMCodeGen", "Parser", "Sema"]),

    .target(name: "AST", dependencies: ["Basic", "Diagnostic"]),
    .target(name: "Basic"),
    .target(name: "Diagnostic", dependencies: ["Basic"]),
    .target(name: "Lexer", dependencies: ["Basic"]),
    .target(name: "LLVMCodeGen", dependencies: ["AST", "LLVM"]),
    .target(name: "Parser", dependencies: ["AST", "Basic", "Lexer"]),
    .target(name: "Sema", dependencies: ["AST"]),

    .testTarget(
      name: "FuelTests",
      dependencies: ["Basic", "Diagnostic", "Fuel"],
      resources: [
        .copy("Sema")
      ]),
    .testTarget(name: "ParserTests", dependencies: ["AST", "Basic", "Lexer", "Parser"]),
  ]
)
