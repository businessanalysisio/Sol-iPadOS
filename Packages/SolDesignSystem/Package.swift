// swift-tools-version: 5.9
// SolDesignSystem — Sol Design System (design.md, ADR-D07/D08)
import PackageDescription

let package = Package(
    name: "SolDesignSystem",
    defaultLocalization: "vi",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SolDesignSystem", targets: ["SolDesignSystem"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0")
    ],
    targets: [
        .target(
            name: "SolDesignSystem",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SolDesignSystemTests",
            dependencies: [
                "SolDesignSystem",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        )
    ]
)
