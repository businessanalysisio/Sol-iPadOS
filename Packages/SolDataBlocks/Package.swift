// swift-tools-version: 5.9
// SolDataBlocks — ```sol-data``` blocks → Swift Charts (PRD APP-FR-09, M3).
import PackageDescription

let package = Package(
    name: "SolDataBlocks",
    defaultLocalization: "vi",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SolDataBlocks", targets: ["SolDataBlocks"])
    ],
    dependencies: [
        .package(path: "../SolDesignSystem")
    ],
    targets: [
        .target(name: "SolDataBlocks", dependencies: ["SolDesignSystem"]),
        .testTarget(name: "SolDataBlocksTests", dependencies: ["SolDataBlocks"]),
    ]
)
