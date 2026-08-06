// swift-tools-version: 5.9
// SolWorkspace — màn S1 (browser, search, palette, sync chip) + Thùng rác.
// PRD v1.2: APP-FR-01/03/04/05/17; chip theo pha M-02 (M1–M3: "Đã lưu cục bộ").
import PackageDescription

let package = Package(
    name: "SolWorkspace",
    defaultLocalization: "vi",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SolWorkspace", targets: ["SolWorkspace"])
    ],
    dependencies: [
        .package(path: "../SolStore"),
        .package(path: "../SolDesignSystem"),
        .package(path: "../SolBootcamp"), // seed BA Bootcamp + Bootcamp Board
    ],
    targets: [
        .target(name: "SolWorkspace",
                dependencies: ["SolStore", "SolDesignSystem", "SolBootcamp"]),
        .testTarget(name: "SolWorkspaceTests", dependencies: ["SolWorkspace"]),
    ]
)
