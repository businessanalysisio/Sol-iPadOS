// swift-tools-version: 5.9
// SolBootcamp — Bootcamp OS: seed content "BA Bootcamp" + backlog engine
// (parse/mutate status trên chính file .md) + dashboard tự tính + Board UI.
// Tài liệu vẫn là markdown thường (APP-FR-10) — engine chỉ sửa đúng ô Status.
import PackageDescription

let package = Package(
    name: "SolBootcamp",
    defaultLocalization: "vi",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SolBootcamp", targets: ["SolBootcamp"])
    ],
    dependencies: [
        .package(path: "../SolStore"),
        .package(path: "../SolDesignSystem"),
        // Test-only: seed + dashboard output must parse through the real
        // M2/M3 pipeline (BlockParser + DataBlockParser).
        .package(path: "../SolBlockModel"),
        .package(path: "../SolDataBlocks"),
    ],
    targets: [
        .target(name: "SolBootcamp", dependencies: ["SolStore", "SolDesignSystem"]),
        .testTarget(name: "SolBootcampTests",
                    dependencies: ["SolBootcamp", "SolBlockModel", "SolDataBlocks"]),
    ]
)
