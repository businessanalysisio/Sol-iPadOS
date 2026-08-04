// swift-tools-version: 5.9
// SolEditor — màn S2: editor 3 chế độ + block gutter + toolbar + journal/autosave.
// PRD v1.2: APP-FR-06/07/08/12.
import PackageDescription

let package = Package(
    name: "SolEditor",
    defaultLocalization: "vi",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SolEditor", targets: ["SolEditor"])
    ],
    dependencies: [
        .package(path: "../SolBlockModel"),
        .package(path: "../SolStore"),
        .package(path: "../SolDesignSystem"),
        .package(path: "../SolDataBlocks"),
    ],
    targets: [
        .target(name: "SolEditor",
                dependencies: ["SolBlockModel", "SolStore", "SolDesignSystem", "SolDataBlocks"]),
        .testTarget(name: "SolEditorTests", dependencies: ["SolEditor"]),
    ]
)
