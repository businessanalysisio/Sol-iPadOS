// swift-tools-version: 5.9
// SolBlockModel — the Markdown Block Model (PRD APP-FR-06/07).
// Pure Swift, no UI: the gutter and the preview both consume THIS parser's
// output, which is what makes the gutter "product truth" (design.md §6).
import PackageDescription

let package = Package(
    name: "SolBlockModel",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SolBlockModel", targets: ["SolBlockModel"])
    ],
    targets: [
        .target(name: "SolBlockModel"),
        .testTarget(name: "SolBlockModelTests", dependencies: ["SolBlockModel"]),
    ]
)
