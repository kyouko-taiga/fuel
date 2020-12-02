// swift-tools-version:5.1
import PackageDescription

let package = Package(
  name: "Fuel",
  platforms: [
    .macOS(.v10_14),
  ],
  products: [
    .executable(name: "fuelc", targets: ["fuelc"]),
    .library(name: "Fuel", targets: ["Fuel"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kyouko-taiga/Diesel", from: "1.0.0"),
    // .package(url: "https://github.com/llvm-swift/LLVMSwift.git", from: "0.4.0"),
  ],
  targets: [
    .target(name: "fuelc", dependencies: ["Fuel"]),
    .target(name: "Fuel", dependencies: ["Diesel"]),
    .testTarget(name: "FuelTests", dependencies: ["Fuel"]),
  ]
)
