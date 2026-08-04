import Foundation

/// Layout metrics — design.md §4.
public enum Sol {
    /// Spacing scale: 2 / 4 / 8 / 12 / 16 / 24 / 32.
    public enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    /// Radius: controls 8–9, cards 12, sheets/panels 14, pills 999. Never 0.
    public enum Radius {
        public static let control: CGFloat = 9
        public static let card: CGFloat = 12
        public static let sheet: CGFloat = 14
        public static let pill: CGFloat = 999
    }

    /// Fixed chrome heights — design.md §6.
    public enum Chrome {
        public static let appBar: CGFloat = 44
        public static let toolbar: CGFloat = 34
        public static let gutterRail: CGFloat = 34
        public static let avatar: CGFloat = 22
    }

    /// Motion durations — design.md §7 (loops must respect Reduce Motion).
    public enum Motion {
        public static let micro: TimeInterval = 0.15
        public static let pane: TimeInterval = 0.30
    }

    /// Overlay shadow — the only sanctioned elevation (design.md §4).
    public enum Elevation {
        public static let overlayRadius: CGFloat = 44
        public static let overlayY: CGFloat = 16
        public static let overlayOpacity: Double = 0.22
    }
}
