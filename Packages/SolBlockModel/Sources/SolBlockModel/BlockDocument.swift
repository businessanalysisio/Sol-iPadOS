import Foundation

/// Parsed document state for the editor. Strategy (deliberate, benchmarked):
///
/// BlockParser is a single linear pass with cheap per-line work, so a FULL
/// reparse of an APP-FR-06-sized document (10k words) costs low single-digit
/// milliseconds — far inside the 50ms keystroke budget. We therefore reparse
/// fully on every edit and keep the machinery simple; `PerformanceTests`
/// asserts the budget on every CI run, and if it ever regresses the
/// escalation path is true block splicing, adopted deliberately (PRD gate
/// tuần 3), not silently.
///
/// What IS incremental: `changedLines` — the tag-diff of the last edit — so
/// the gutter redraws only the lines whose tag actually changed.
public final class BlockDocument {
    public private(set) var lines: [String]
    public private(set) var result: ParseResult
    public private(set) var changedLines: Range<Int>

    public init(text: String) {
        lines = text.components(separatedBy: "\n")
        result = BlockParser.parse(lines: lines)
        changedLines = 0..<lines.count
    }

    public var text: String { lines.joined(separator: "\n") }

    public func replaceAll(with text: String) {
        let oldTypes = result.lineTypes
        lines = text.components(separatedBy: "\n")
        result = BlockParser.parse(lines: lines)
        changedLines = Self.diffRange(old: oldTypes, new: result.lineTypes)
    }

    /// Tag-diff: smallest line range outside of which old and new tags agree.
    static func diffRange(old: [BlockType], new: [BlockType]) -> Range<Int> {
        var start = 0
        while start < min(old.count, new.count), old[start] == new[start] { start += 1 }
        var oldEnd = old.count, newEnd = new.count
        while oldEnd > start, newEnd > start, old[oldEnd - 1] == new[newEnd - 1] {
            oldEnd -= 1; newEnd -= 1
        }
        return start..<max(start, newEnd)
    }
}
