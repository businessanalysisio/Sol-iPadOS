// swift-tools-version: 5.9
// SolStore — file-based document store, iCloud/local fallback, FTS index, trash.
// PRD v1.2: APP-FR-03/04/10/15/17, APP-BR-02/03/04.
import PackageDescription

let package = Package(
    name: "SolStore",
    platforms: [.iOS(.v17), .macOS(.v14)], // macOS for fast headless CI tests
    products: [
        .library(name: "SolStore", targets: ["SolStore"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.27.0")
    ],
    targets: [
        .target(
            name: "SolStore",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")]
        ),
        .testTarget(name: "SolStoreTests", dependencies: ["SolStore"]),
    ]
)
