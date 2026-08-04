import Foundation

/// Line-oriented Markdown parser. One pass yields both the preview tree and
/// the gutter tags (ParseResult).
///
/// Engine works on UTF-8 bytes: every Markdown marker is ASCII, and UTF-8 is
/// self-synchronizing, so slicing at ASCII marker/newline positions can never
/// split a Vietnamese multi-byte character. Strings materialize only for
/// content payloads. (Character-based scanning cost ~200ms/10k words in
/// Debug; this engine exists because the perf tripwire said so.)
public enum BlockParser {

    public static func parse(_ text: String) -> ParseResult {
        let bytes = Array(text.utf8)
        var lineRanges: [Range<Int>] = []
        var start = 0
        for i in 0..<bytes.count where bytes[i] == 0x0A { // \n
            lineRanges.append(start..<i); start = i + 1
        }
        lineRanges.append(start..<bytes.count)
        return parse(bytes: bytes, lineRanges: lineRanges)
    }

    public static func parse(lines: [String]) -> ParseResult {
        parse(lines.joined(separator: "\n"))
    }

    // MARK: - Byte engine

    private static func parse(bytes: [UInt8], lineRanges: [Range<Int>]) -> ParseResult {
        var blocks: [Block] = []
        var types: [BlockType] = []
        types.reserveCapacity(lineRanges.count)
        var i = 0

        func line(_ n: Int) -> ArraySlice<UInt8> { bytes[lineRanges[n]] }

        while i < lineRanges.count {
            let l = line(i)

            if hasPrefix(l, [0x60, 0x60, 0x60]) { // ```
                let info = decode(l.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var body: [String] = []
                types.append(.fence); i += 1
                while i < lineRanges.count, !hasPrefix(line(i), [0x60, 0x60, 0x60]) {
                    body.append(decode(line(i))); types.append(.fence); i += 1
                }
                if i < lineRanges.count { types.append(.fence); i += 1 }
                blocks.append(.fence(info: info, body: body))
            } else if hasPrefix(l, [0x23, 0x20]) { // "# "
                blocks.append(.heading(level: 1, content: inline(l.dropFirst(2))))
                types.append(.h1); i += 1
            } else if hasPrefix(l, [0x23, 0x23, 0x20]) { // "## "
                blocks.append(.heading(level: 2, content: inline(l.dropFirst(3))))
                types.append(.h2); i += 1
            } else if hasPrefix(l, [0x3E, 0x20]) { // "> "
                blocks.append(.quote(inline(l.dropFirst(2))))
                types.append(.quote); i += 1
            } else if hasPrefix(l, [0x2D, 0x20]) { // "- "
                var items: [[Inline]] = []
                while i < lineRanges.count, hasPrefix(line(i), [0x2D, 0x20]) {
                    items.append(inline(line(i).dropFirst(2)))
                    types.append(.list); i += 1
                }
                blocks.append(.list(items: items))
            } else if isTable(l) {
                var raw: [[[Inline]]] = []
                while i < lineRanges.count, isTable(line(i)) {
                    if !isSeparator(line(i)) { raw.append(cells(line(i)).map { inline($0) }) }
                    types.append(.table); i += 1
                }
                blocks.append(.table(header: raw.first ?? [], rows: Array(raw.dropFirst())))
            } else if isBlank(l) {
                types.append(.empty); i += 1
            } else {
                blocks.append(.paragraph(inline(l)))
                types.append(.paragraph); i += 1
            }
        }
        return ParseResult(blocks: blocks, lineTypes: types)
    }

    // Ordering note: "## " is checked before "# " never matters here because
    // [0x23, 0x20] fails on "##" (second byte 0x23 ≠ 0x20) — both branches are
    // mutually exclusive by construction.

    private static func decode(_ slice: ArraySlice<UInt8>) -> String {
        String(decoding: slice, as: UTF8.self)
    }

    private static func hasPrefix(_ slice: ArraySlice<UInt8>, _ prefix: [UInt8]) -> Bool {
        guard slice.count >= prefix.count else { return false }
        var idx = slice.startIndex
        for b in prefix {
            if slice[idx] != b { return false }
            idx += 1
        }
        return true
    }

    private static func isBlank(_ slice: ArraySlice<UInt8>) -> Bool {
        slice.allSatisfy { $0 == 0x20 || $0 == 0x09 }
    }

    private static func trimmed(_ slice: ArraySlice<UInt8>) -> ArraySlice<UInt8> {
        var s = slice.startIndex, e = slice.endIndex
        while s < e, slice[s] == 0x20 || slice[s] == 0x09 { s += 1 }
        while e > s, slice[e - 1] == 0x20 || slice[e - 1] == 0x09 { e -= 1 }
        return slice[s..<e]
    }

    private static func isTable(_ slice: ArraySlice<UInt8>) -> Bool {
        trimmed(slice).first == 0x7C // |
    }

    private static func isSeparator(_ slice: ArraySlice<UInt8>) -> Bool {
        let t = trimmed(slice)
        guard t.first == 0x7C else { return false }
        return t.allSatisfy { $0 == 0x7C || $0 == 0x2D || $0 == 0x3A || $0 == 0x20 }
    }

    /// Splits a table line into trimmed cell slices (drops outer empties).
    private static func cells(_ slice: ArraySlice<UInt8>) -> [ArraySlice<UInt8>] {
        var parts: [ArraySlice<UInt8>] = []
        var start = slice.startIndex
        var idx = slice.startIndex
        while idx < slice.endIndex {
            if slice[idx] == 0x7C {
                parts.append(trimmed(slice[start..<idx]))
                start = idx + 1
            }
            idx += 1
        }
        parts.append(trimmed(slice[start..<slice.endIndex]))
        if parts.first?.isEmpty == true { parts.removeFirst() }
        if parts.last?.isEmpty == true { parts.removeLast() }
        return parts
    }

    /// Inline pass over a byte slice — see InlineParser for the String API.
    static func inline(_ slice: ArraySlice<UInt8>) -> [Inline] {
        // Fast path: no '*' (0x2A) and no '`' (0x60).
        guard slice.contains(where: { $0 == 0x2A || $0 == 0x60 }) else {
            return slice.isEmpty ? [] : [.text(decode(slice))]
        }

        var result: [Inline] = []
        var plainStart = slice.startIndex
        var i = slice.startIndex

        func flushPlain(upTo end: Int) {
            if end > plainStart { result.append(.text(decode(slice[plainStart..<end]))) }
        }
        func find(_ marker: [UInt8], from: Int) -> Int? {
            var j = from
            while j + marker.count <= slice.endIndex {
                var k = 0
                while k < marker.count, slice[j + k] == marker[k] { k += 1 }
                if k == marker.count { return j }
                j += 1
            }
            return nil
        }
        func consume(_ marker: [UInt8], _ make: (String) -> Inline) -> Bool {
            let contentStart = i + marker.count
            guard let close = find(marker, from: contentStart), close > contentStart else { return false }
            flushPlain(upTo: i)
            result.append(make(decode(slice[contentStart..<close])))
            i = close + marker.count
            plainStart = i
            return true
        }

        while i < slice.endIndex {
            let b = slice[i]
            if b == 0x2A, i + 1 < slice.endIndex, slice[i + 1] == 0x2A,
               consume([0x2A, 0x2A], { .bold($0) }) { continue }
            if b == 0x2A, consume([0x2A], { .italic($0) }) { continue }
            if b == 0x60, consume([0x60], { .code($0) }) { continue }
            i += 1
        }
        flushPlain(upTo: slice.endIndex)
        return result
    }
}
