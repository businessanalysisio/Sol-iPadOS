import Foundation

/// Per-line block tag — exactly the vocabulary the gutter renders (mockup v2,
/// design.md §6). Structural tags (all but `paragraph`/`empty`) use `accent`.
public enum BlockType: String, Equatable {
    case h1 = "H1"
    case h2 = "H2"
    case table = "TB"
    case quote = "BQ"
    case list = "UL"
    case fence = "DB"
    case paragraph = "P"
    case empty = "·"

    /// Accent tags per design.md §6 (CR-D2: UL included).
    public var isStructural: Bool { self != .paragraph && self != .empty }
}

/// Inline span — bold / italic / code over plain text.
public enum Inline: Equatable {
    case text(String)
    case bold(String)
    case italic(String)
    case code(String)
}

/// A rendered block in the preview tree.
public enum Block: Equatable {
    case heading(level: Int, content: [Inline])
    case paragraph([Inline])
    case quote([Inline])
    case list(items: [[Inline]])
    case table(header: [[Inline]], rows: [[[Inline]]])
    case fence(info: String, body: [String])
}

/// Parse result: the render tree AND the per-line tags, produced by the SAME
/// pass. The gutter cannot drift from the preview because there is no second
/// classifier (APP-FR-07 AC: "khớp 100%").
public struct ParseResult: Equatable {
    public let blocks: [Block]
    public let lineTypes: [BlockType]
}
