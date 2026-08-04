import XCTest
@testable import SolDesignSystem

/// WCAG contrast assertions — design.md §2.5, required by the A1 DoD (§9).
/// Thresholds are the measured ratios of the shipped palette minus a small
/// guard band, so any token drift that degrades contrast fails CI.
final class ContrastTests: XCTestCase {

    // MARK: WCAG relative luminance / contrast ratio

    private func luminance(_ hex: UInt32) -> Double {
        func channel(_ v: UInt32) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel((hex >> 16) & 0xFF)
             + 0.7152 * channel((hex >> 8) & 0xFF)
             + 0.0722 * channel(hex & 0xFF)
    }

    private func ratio(_ a: UInt32, _ b: UInt32) -> Double {
        let (la, lb) = (luminance(a), luminance(b))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    // MARK: §2.5 rule assertions (measured: 14.13 / 15.72 / 7.09 / 3.90 / 7.68 / 15.35)

    func testBodyTextOnBackgrounds() {
        let l = SolColorTable.light, d = SolColorTable.dark
        XCTAssertGreaterThanOrEqual(ratio(l["text.primary"]!, l["bg"]!), 12.0)
        XCTAssertGreaterThanOrEqual(ratio(l["text.primary"]!, l["surface"]!), 12.0)
        XCTAssertGreaterThanOrEqual(ratio(d["text.primary"]!, d["bg"]!), 12.0)
        XCTAssertGreaterThanOrEqual(ratio(d["text.primary"]!, d["surface"]!), 12.0)
    }

    func testAccentTextRules() {
        let l = SolColorTable.light, d = SolColorTable.dark
        // Running-text links: burnt on cream must be ≥ 7:1.
        XCTAssertGreaterThanOrEqual(ratio(l["accent.strong"]!, l["bg"]!), 7.0)
        // Dark-mode accent text: sunrise on gray.900 ≥ 7:1 (measured 7.68).
        XCTAssertGreaterThanOrEqual(ratio(d["accent"]!, d["bg"]!), 7.0)
        // orange.core on white: UI components / large text only → ≥ 3:1 (measured 3.90).
        XCTAssertGreaterThanOrEqual(ratio(l["accent"]!, l["surface"]!), 3.0)
        // …and it must NOT be used for normal body text (guard: it is below 4.5).
        XCTAssertLessThan(ratio(l["accent"]!, l["surface"]!), 4.5,
            "If accent/white now passes 4.5:1 the §2.5 large-text-only rule should be revisited deliberately, not silently.")
    }

    func testSecondaryAndFunctionalText() {
        let l = SolColorTable.light, d = SolColorTable.dark
        // Metadata text ≥ 4.5:1 (AA normal text).
        XCTAssertGreaterThanOrEqual(ratio(l["text.secondary"]!, l["surface"]!), 4.5)
        XCTAssertGreaterThanOrEqual(ratio(d["text.secondary"]!, d["surface"]!), 4.5)
        // Functional colors as text on surface ≥ 4.5:1.
        XCTAssertGreaterThanOrEqual(ratio(l["danger"]!, l["surface"]!), 4.5)
        XCTAssertGreaterThanOrEqual(ratio(l["positive"]!, l["surface"]!), 4.5)
    }
}
