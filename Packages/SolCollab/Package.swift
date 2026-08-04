// swift-tools-version: 5.9
// SolCollab — Live Share client (APP-FR-13/14, phát hành v1.1).
// KHÔNG link vào app target v1 (HR-2); Layer-1 theo ADR-A03: toàn bộ state
// machine + hội tụ CRDT test tất định qua relay mock cài đúng SPEC-RELAY §4.
import PackageDescription

let package = Package(
    name: "SolCollab",
    defaultLocalization: "vi",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SolCollab", targets: ["SolCollab"])
    ],
    dependencies: [
        .package(path: "../SolDesignSystem")
    ],
    targets: [
        .target(name: "SolCollab", dependencies: ["SolDesignSystem"]),
        .testTarget(name: "SolCollabTests", dependencies: ["SolCollab"]),
    ]
)
