// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TerraControl",
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "TerraControlCore",
      targets: ["TerraControlCore"]),
    .executable(
      name: "terracontrol",
      targets: ["TerraControl"])
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/Bouke/HAP", .branch("master")),
    .package(url: "https://github.com/apple/swift-log.git", Version("0.0.0") ..< Version("2.0.0")),
    .package(url: "https://github.com/kylef/Commander", Version("0.9.1") ..< Version("1.0.0")),
    .package(url: "https://github.com/thbonk/Pushover", .branch("master")),
    .package(url: "https://github.com/Quick/Quick", from: "3.0.0"),
    .package(url: "https://github.com/Quick/Nimble", from: "9.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "TerraControl",
      dependencies: [
        "TerraControlCore",
        "Commander",
        "Pushover"]),
    .target(
      name: "TerraControlCore",
      dependencies: [
        "HAP",
        "Pushover",
        .product(name: "Logging", package: "swift-log")]),
    .testTarget(
      name: "TerraControlCoreTests",
      dependencies: ["TerraControlCore", "Quick", "Nimble"],
      resources: [.process("Testdata/configuration.json")]),
  ]
)
