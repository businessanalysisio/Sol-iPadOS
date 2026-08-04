import SwiftUI
import UIKit

/// Semantic color tokens — design.md §2.2. Names match the spec exactly.
///
/// ADR-M0-01: tokens ship as code constants + dynamic providers (not an asset
/// catalog). Same naming contract as design.md §9, single source of truth,
/// and the hex table stays assertable by `ContrastTests` in CI. Revisit only
/// if design tooling requires .xcassets.
public enum SolColor {
    // MARK: Semantic tokens (light / dark)
    public static let bg            = dynamic(0xF8F2EA, 0x191512)
    public static let surface       = dynamic(0xFFFFFF, 0x241C16)
    public static let surfaceAlt    = dynamic(0xF3F4F6, 0x2B211B)
    public static let textPrimary   = dynamic(0x2B211B, 0xF3EBE0)
    public static let textSecondary = dynamic(0x6B7280, 0xB9A895)
    public static let accent        = dynamic(0xD85A0B, 0xFF8A00)
    public static let accentStrong  = dynamic(0x8F3408, 0xD85A0B)
    public static let border        = dynamic(0xEAE0D3, 0x3A2E24)
    public static let positive      = dynamic(0x3B7A3F, 0x6FBF73)
    public static let danger        = dynamic(0xC2452F, 0xE06A54)
    /// Conflict banners — sunrise tint 12% + burnt text (design.md §2.2 "warning").
    public static let warningTint   = dynamic(0xFF8A00, 0xFF8A00, alpha: 0.12)

    // MARK: Data-visualization ramp — design.md §2.3, in order.
    public static let chartRamp: [Color] = [0xD85A0B, 0xFF8A00, 0x8F3408, 0x384152, 0x6B7280].map { Color(hex: $0) }

    // MARK: Presence palette — design.md §2.4 (self uses `accent`).
    public static let peer1 = Color(hex: 0x384152) // slate
    public static let peer2 = Color(hex: 0x7C6BD9) // violet
    public static let peer3 = Color(hex: 0x2E7D74) // teal
    public static let presenceSelectionAlpha: Double = 0.18

    private static func dynamic(_ light: UInt32, _ dark: UInt32, alpha: CGFloat = 1) -> Color {
        Color(UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light, alpha: alpha)
        })
    }
}

/// Hex table exposed for CI contrast assertions (design.md §2.5).
/// Kept next to the tokens above so the two cannot drift silently.
public enum SolColorTable {
    public static let light: [String: UInt32] = [
        "bg": 0xF8F2EA, "surface": 0xFFFFFF, "surface.alt": 0xF3F4F6,
        "text.primary": 0x2B211B, "text.secondary": 0x6B7280,
        "accent": 0xD85A0B, "accent.strong": 0x8F3408, "border": 0xEAE0D3,
        "positive": 0x3B7A3F, "danger": 0xC2452F,
    ]
    public static let dark: [String: UInt32] = [
        "bg": 0x191512, "surface": 0x241C16, "surface.alt": 0x2B211B,
        "text.primary": 0xF3EBE0, "text.secondary": 0xB9A895,
        "accent": 0xFF8A00, "accent.strong": 0xD85A0B, "border": 0x3A2E24,
        "positive": 0x6FBF73, "danger": 0xE06A54,
    ]
}

public extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(UIColor(hex: hex, alpha: alpha))
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
