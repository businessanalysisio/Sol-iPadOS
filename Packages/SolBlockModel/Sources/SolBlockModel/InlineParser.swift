import Foundation

/// Inline Markdown: `**bold**`, `*italic*`, `` `code` ``. Manual scan over a
/// character array — no Foundation `range(of:)` (its NSString bridging made
/// a 10k-word reparse cost ~400ms in Debug; this path sits on every
/// keystroke, G1/APP-NFR-01).
public enum InlineParser {
    public static func parse(_ text: String) -> [Inline] {
        // Fast path: most lines carry no markers at all.
        guard text.contains("*") || text.contains("`") else {
            return text.isEmpty ? [] : [.text(text)]
        }

        let chars = Array(text)
        var result: [Inline] = []
        var plain = String()
        var i = 0

        func flushPlain() {
            if !plain.isEmpty { result.append(.text(plain)); plain = "" }
        }

        /// Index of the next occurrence of `marker` at/after `from`, or nil.
        func find(_ marker: [Character], from: Int) -> Int? {
            guard from < chars.count else { return nil }
            var j = from
            while j + marker.count <= chars.count {
                var k = 0
                while k < marker.count, chars[j + k] == marker[k] { k += 1 }
                if k == marker.count { return j }
                j += 1
            }
            return nil
        }

        /// Consumes a delimited span if a closing marker exists with non-empty
        /// content; returns false to let the caller treat the char as literal.
        func consumeSpan(_ marker: [Character], _ make: (String) -> Inline) -> Bool {
            let contentStart = i + marker.count
            guard let close = find(marker, from: contentStart), close > contentStart else { return false }
            flushPlain()
            result.append(make(String(chars[contentStart..<close])))
            i = close + marker.count
            return true
        }

        while i < chars.count {
            let c = chars[i]
            if c == "*", i + 1 < chars.count, chars[i + 1] == "*", consumeSpan(["*", "*"], { .bold($0) }) {
                continue
            }
            if c == "*", consumeSpan(["*"], { .italic($0) }) { continue }
            if c == "`", consumeSpan(["`"], { .code($0) }) { continue }
            plain.append(c)
            i += 1
        }
        flushPlain()
        return result
    }
}
