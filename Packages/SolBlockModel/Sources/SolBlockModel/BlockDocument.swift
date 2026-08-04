import Foundation

/// Parsed document state for the editor. Strategy (deliberate, benchmarked):
///
/// BlockParser is a single UTF-8 pass, so a FULL reparse of an APP-FR-06
/// tier-1 document (10k words) costs low tens of ms even in Debug. We reparse
/// fully on every edit and keep the machinery simple; `PerformanceTests` pins
/// the budget on every CI run, and the escalation path if it ever regresses
/// is true block splicing — adopted deliberately, never silently.
///
/// Hot-path discipline: `text` is the single source of truth and goes to the
/// parser directly. (An earlier revision split into a lines array and re-joined
/// per keystroke — three full-document copies that tripled the parse cost;
/// the tripwire caught it.)
///
/// What IS incremental: `changedLines` — the tag-diff of the last edit — so
/// the gutter redraws only lines whose tag actually changed.
public final class BlockDocument {
    public private(set) var text: String
    public private(set) var result: ParseResult
    public private(set) var changedLines: Range<Int>

    public init(text: String) {
        self.text = text
        result = BlockParser.parse(text)
        changedLines = 0..<result.lineTypes.count
    }

    public func replaceAll(with newText: String) {
        let oldTypes = result.lineTypes
        text = newText
        result = BlockParser.parse(newText)
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
