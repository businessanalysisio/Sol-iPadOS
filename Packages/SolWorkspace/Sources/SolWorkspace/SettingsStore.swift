import SwiftUI
import Observation
import SolStore

/// App theme — applied at the root via preferredColorScheme, so switching
/// takes effect immediately, no restart (APP-FR-16 AC).
public enum SolTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .system: "Theo hệ thống"
        case .light: "Sáng"
        case .dark: "Tối"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// UI languages shipped in v1 (PRD §9 Localization).
public enum SolLanguage: String, CaseIterable, Identifiable {
    case vi, en
    public var id: String { rawValue }
    public var label: String { self == .vi ? "Tiếng Việt" : "English" }
}

/// Settings state — UserDefaults-backed, injectable for tests.
@Observable
public final class SettingsStore {
    public static let themeKey = "sol.settings.theme"
    public static let languageKey = "sol.settings.language"

    private let defaults: UserDefaults
    public let telemetry: TelemetryLog?

    public var theme: SolTheme {
        didSet { defaults.set(theme.rawValue, forKey: Self.themeKey) }
    }

    public var language: SolLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Self.languageKey)
            // AppleLanguages is honored at next launch — the UI must say so
            // (AC: "cho phép yêu cầu restart, phải thông báo").
            defaults.set([language.rawValue], forKey: "AppleLanguages")
        }
    }

    /// True when the chosen language differs from the one this process runs in.
    public var restartNeededForLanguage: Bool {
        let running = Locale.current.language.languageCode?.identifier ?? "vi"
        return running != language.rawValue
    }

    public var telemetryEnabled: Bool {
        get { telemetry?.isEnabled ?? false }
        set { telemetry?.isEnabled = newValue }
    }

    public init(defaults: UserDefaults = .standard, telemetry: TelemetryLog? = nil) {
        self.defaults = defaults
        self.telemetry = telemetry
        theme = SolTheme(rawValue: defaults.string(forKey: Self.themeKey) ?? "") ?? .system
        language = SolLanguage(rawValue: defaults.string(forKey: Self.languageKey) ?? "") ?? .vi
    }
}

/// Phụ lục A — the shortcuts that live OUTSIDE the palette. Same closed-list
/// discipline as SolCommandID: Settings renders palette commands + this list,
/// and a test pins both against the PRD.
public enum NonPaletteShortcuts {
    public static let all: [(action: String, keys: String)] = [
        ("In đậm", "⌘B"),
        ("In nghiêng", "⌘I"),
        ("Heading 2", "⌘⇧H"),
        ("Danh sách", "⌘⇧L"),
        ("Trích dẫn", "⌘⇧Q"),
        ("Đóng overlay", "Esc"),
        ("Đóng cửa sổ", "⌘W"),
        ("Mở Settings", "⌘,"),
    ]
}
