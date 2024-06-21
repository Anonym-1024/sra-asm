// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sra-asm",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SRA-ASM",
            targets: ["sra-asm"]),
    ],
    dependencies: [
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "sra-asm",
            dependencies: [],
            exclude: ["Resources/Grammar_asm.txt", "Resources/Grammar_ash.txt", "Resources/Grammar_asm_ebnf.txt", "Resources/Grammar_ash_ebnf.txt"],
            resources: [.copy("Resources/Instructions.txt"), .copy("Resources/Instruction_format.csv"), .copy("Resources/Keywords_asm.txt"), .copy("Resources/Keywords_ash.txt")]
            
            ),
        .executableTarget(name: "sra-asm-driver", dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"), .target(name: "sra-asm")])
    ]
)
