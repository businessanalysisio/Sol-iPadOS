import Foundation

/// String facade over the byte-level inline engine in BlockParser (kept for
/// API stability and direct unit-testing of inline behavior).
public enum InlineParser {
    public static func parse(_ text: String) -> [Inline] {
        let bytes = Array(text.utf8)
        return BlockParser.inline(bytes[bytes.startIndex...])
    }
}
