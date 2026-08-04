import XCTest
import SwiftUI
import SnapshotTesting
@testable import SolDesignSystem

/// Snapshot matrix — A1 DoD (design.md §9, CR-D1): both themes × all three
/// split-view ratios × Dynamic Type XL, on the reference-device logical size.
///
/// First run on a Mac records baselines (`--record` / SNAPSHOT_RECORD=1);
/// afterwards any pixel drift fails CI. Run on the pinned simulator only
/// (iPad (10th generation), iPadOS 17.x) — snapshots are device-specific.
final class SnapshotTests: XCTestCase {

    // iPad (10th gen) landscape logical size: 1180×820 (HR-4 reference device).
    private static let fullWidth: CGFloat = 1180
    private static let height: CGFloat = 820

    /// APP-FR-02 split ratios → pane widths at full landscape width.
    private static let splitWidths: [(name: String, width: CGFloat)] = [
        ("split50", fullWidth * 0.50),  // 50/50 → 590
        ("split33", fullWidth * 0.33),  // 33/67 → 389 (narrow pane)
        ("split67", fullWidth * 0.67),  // 67/33 → 791
    ]

    override class func setUp() {
        super.setUp()
        SolFontRegistrar.registerAll()
    }

    @MainActor
    func testGalleryMatrix() {
        for scheme in [ColorScheme.light, ColorScheme.dark] {
            for split in Self.splitWidths {
                for (sizeName, size) in [("default", DynamicTypeSize.large), ("DTXL", DynamicTypeSize.xLarge)] {
                    let view = DesignSystemGallery()
                        .environment(\.colorScheme, scheme)
                        .environment(\.dynamicTypeSize, size)
                        .frame(width: split.width, height: Self.height)
                        .background(SolColor.bg)

                    assertSnapshot(
                        of: UIHostingController(rootView: view),
                        as: .image(size: CGSize(width: split.width, height: Self.height)),
                        named: "\(scheme == .dark ? "dark" : "light")_\(split.name)_\(sizeName)"
                    )
                }
            }
        }
    }
}
