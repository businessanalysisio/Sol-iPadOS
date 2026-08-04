import XCTest
import CoreText
@testable import SolDesignSystem

/// Vietnamese glyph coverage — PRD v1.2 Phụ lục C / APP-NFR-07.
/// Guards the exact failure that killed Poppins (ADR-D08): a bundled font
/// missing precomposed Vietnamese glyphs (đ/Đ, ơ/ư, U+1EA0–1EFF).
final class VietnameseGlyphTests: XCTestCase {

    /// Full Vietnamese alphabet incl. every tone mark — 134 non-ASCII characters.
    private static let vietnameseChars: [Character] = {
        let lower = "aáàảãạăắằẳẵặâấầẩẫậbcdđeéèẻẽẹêếềểễệghiíìỉĩịklmnoóòỏõọôốồổỗộơớờởỡợpqrstuúùủũụưứừửữựvxyýỳỷỹỵ"
        return Array(Set((lower + lower.uppercased()).filter { $0.asciiValue == nil })).sorted()
    }()

    override class func setUp() {
        super.setUp()
        SolFontRegistrar.registerAll()
    }

    func testAllRequiredFontsAreRegistered() {
        for name in SolFontRegistrar.requiredFonts {
            let font = CTFontCreateWithName(name as CFString, 15, nil)
            let resolved = CTFontCopyPostScriptName(font) as String
            XCTAssertEqual(resolved, name, "Font \(name) did not resolve — bundle/registration broken (got \(resolved))")
        }
    }

    func testEveryBundledFontCoversFullVietnameseAlphabet() {
        for name in SolFontRegistrar.requiredFonts {
            let font = CTFontCreateWithName(name as CFString, 15, nil)
            var missing: [Character] = []
            for ch in Self.vietnameseChars {
                var chars = Array(String(ch).utf16)
                var glyphs = [CGGlyph](repeating: 0, count: chars.count)
                let mapped = CTFontGetGlyphsForCharacters(font, &chars, &glyphs, chars.count)
                if !mapped || glyphs.contains(0) { missing.append(ch) }
            }
            XCTAssertTrue(missing.isEmpty,
                "\(name) is missing \(missing.count)/134 Vietnamese glyphs: \(String(missing))")
        }
    }

    /// NFC (precomposed) and NFD (combining) forms must both render — design.md §3.
    func testPrecomposedAndCombiningFormsEquivalent() {
        let nfc = "đặc tả ưu đãi ế ộ ờ"
        let nfd = nfc.decomposedStringWithCanonicalMapping
        XCTAssertNotEqual(Array(nfc.utf16), Array(nfd.utf16), "test strings should differ at UTF-16 level")
        XCTAssertEqual(nfd.precomposedStringWithCanonicalMapping, nfc)
        // Shaping check: both forms must produce a full glyph run in the heading font.
        let font = CTFontCreateWithName("BeVietnamPro-SemiBold" as CFString, 17, nil)
        for form in [nfc, nfd] {
            let attr = NSAttributedString(string: form, attributes: [.font: font])
            let line = CTLineCreateWithAttributedString(attr)
            XCTAssertGreaterThan(CTLineGetGlyphCount(line), 0)
        }
    }
}
