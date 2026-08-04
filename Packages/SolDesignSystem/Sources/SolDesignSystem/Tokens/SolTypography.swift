import SwiftUI
import CoreText

/// Typography roles — design.md §3 (ADR-D08: Be Vietnam Pro replaces Poppins).
/// All sizes scale with Dynamic Type via `relativeTo`.
public enum SolFont {
    // Heading faces — Be Vietnam Pro ONLY for headings/subheads.
    public static func display() -> Font { .custom("BeVietnamPro-Bold", size: 28, relativeTo: .largeTitle) }
    public static func h1() -> Font { .custom("BeVietnamPro-SemiBold", size: 22, relativeTo: .title) }
    public static func h2() -> Font { .custom("BeVietnamPro-SemiBold", size: 17, relativeTo: .title3) }
    public static func subheading() -> Font { .custom("BeVietnamPro-Medium", size: 15, relativeTo: .headline) }
    /// App-bar title — design.md §6 (Be Vietnam Pro SemiBold 14–15).
    public static func barTitle() -> Font { .custom("BeVietnamPro-SemiBold", size: 15, relativeTo: .headline) }

    // Functional faces — everything functional is Inter.
    public static func body() -> Font { .custom("Inter-Regular", size: 15, relativeTo: .body) }
    public static func label() -> Font { .custom("Inter-Medium", size: 12, relativeTo: .caption) }
    public static func labelStrong() -> Font { .custom("Inter-SemiBold", size: 13, relativeTo: .caption) }
    /// Numbers/data: tabular figures ON (design.md §3).
    public static func data() -> Font { .custom("Inter-SemiBold", size: 13, relativeTo: .caption).monospacedDigit() }
    /// Markdown source / code: SF Mono fallback chain (design.md §3).
    public static func mono() -> Font { .system(size: 13, design: .monospaced) }

    /// Label tracking +2% (design.md §3); apply via `.kerning(SolFont.labelTracking(for:))`.
    public static func labelTracking(for size: CGFloat = 12) -> CGFloat { size * 0.02 }
}

/// Registers bundled fonts (Be Vietnam Pro, Inter) with CoreText.
/// Call once at app launch, before any view renders: `SolFontRegistrar.registerAll()`.
public enum SolFontRegistrar {
    @discardableResult
    public static func registerAll() -> [String] {
        guard let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil), !urls.isEmpty else {
            assertionFailure("SolDesignSystem: no bundled .ttf resources found")
            return []
        }
        var registered: [String] = []
        for url in urls {
            var error: Unmanaged<CFError>?
            // Already-registered fonts return an error; that is fine (idempotent).
            if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                registered.append(url.lastPathComponent)
            }
        }
        return registered
    }

    /// PostScript names the design system depends on — asserted by tests.
    public static let requiredFonts = [
        "BeVietnamPro-Medium", "BeVietnamPro-SemiBold", "BeVietnamPro-Bold",
        "Inter-Regular", "Inter-Medium", "Inter-SemiBold",
    ]
}
