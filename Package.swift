// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swonsole",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Swonsole",
            targets: ["Swonsole"]),
        .executable(name: "SwonsoleTest", targets: ["SwonsoleTest"])
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Swonsole",
            dependencies: ["Rainbow"]),
        .target(name: "SwonsoleTest", dependencies: [.target(name: "Swonsole")]),
        .testTarget(
            name: "SwonsoleTests",
            dependencies: ["Swonsole"]),
    ]
)
