import Foundation

/// Inline Markdown: `**bold**`, `*italic*`, `` `code` ``. Single pass, no
/// regex backtracking — inline parsing sits on the keystroke path (G1).
public enum InlineParser {
    public static func parse(_ text: String) -> [Inline] {
        var result: [Inline] = []
        var plain = ""
        var i = text.startIndex

        func flushPlain() {
            if !plain.isEmpty { result.append(.text(plain)); plain = "" }
        }
        /// Scans for `close` after `from`; returns (content, indexAfterClose).
        func span(from: String.Index, close: String) -> (String, String.Index)? {
            guard let r = text.range(of: close, range: from..<text.endIndex),
                  r.lowerBound > from else { return nil }
            return (String(text[from..<r.lowerBound]), r.upperBound)
        }

        while i < text.endIndex {
            if text[i...].hasPrefix("**"), let (s, after) = span(from: text.index(i, offsetBy: 2), close: "**") {
                flushPlain(); result.append(.bold(s)); i = after
            } else if text[i] == "*", let (s, after) = span(from: text.index(after: i), close: "*") {
                flushPlain(); result.append(.italic(s)); i = after
            } else if text[i] == "`", let (s, after) = span(from: text.index(after: i), close: "`") {
                flushPlain(); result.append(.code(s)); i = after
            } else {
                plain.append(text[i]); i = text.index(after: i)
            }
        }
        flushPlain()
        return result
    }
}
