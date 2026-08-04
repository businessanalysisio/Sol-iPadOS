import Foundation

/// Line-oriented Markdown parser. One pass over the lines yields both the
/// preview tree and the gutter tags (ParseResult).
public enum BlockParser {

    public static func parse(_ text: String) -> ParseResult {
        parse(lines: text.components(separatedBy: "\n"))
    }

    public static func parse(lines: [String]) -> ParseResult {
        var blocks: [Block] = []
        var types: [BlockType] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]

            if line.hasPrefix("```") {
                // Fenced block: everything to the closing fence is DB.
                let info = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var body: [String] = []
                types.append(.fence)
                i += 1
                while i < lines.count, !lines[i].hasPrefix("```") {
                    body.append(lines[i]); types.append(.fence); i += 1
                }
                if i < lines.count { types.append(.fence); i += 1 } // closing fence
                blocks.append(.fence(info: info, body: body))
            } else if line.hasPrefix("# ") {
                blocks.append(.heading(level: 1, content: InlineParser.parse(String(line.dropFirst(2)))))
                types.append(.h1); i += 1
            } else if line.hasPrefix("## ") {
                blocks.append(.heading(level: 2, content: InlineParser.parse(String(line.dropFirst(3)))))
                types.append(.h2); i += 1
            } else if line.hasPrefix("> ") {
                blocks.append(.quote(InlineParser.parse(String(line.dropFirst(2)))))
                types.append(.quote); i += 1
            } else if line.hasPrefix("- ") {
                var items: [[Inline]] = []
                while i < lines.count, lines[i].hasPrefix("- ") {
                    items.append(InlineParser.parse(String(lines[i].dropFirst(2))))
                    types.append(.list); i += 1
                }
                blocks.append(.list(items: items))
            } else if isTableLine(line) {
                var raw: [[String]] = []
                while i < lines.count, isTableLine(lines[i]) {
                    if !isSeparatorLine(lines[i]) { raw.append(cells(of: lines[i])) }
                    types.append(.table); i += 1
                }
                let parsed = raw.map { $0.map(InlineParser.parse) }
                blocks.append(.table(header: parsed.first ?? [], rows: Array(parsed.dropFirst())))
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                types.append(.empty); i += 1
            } else {
                blocks.append(.paragraph(InlineParser.parse(line)))
                types.append(.paragraph); i += 1
            }
        }
        return ParseResult(blocks: blocks, lineTypes: types)
    }

    // MARK: Table helpers

    static func isTableLine(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasPrefix("|")
    }

    static func isSeparatorLine(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard t.hasPrefix("|") else { return false }
        return t.allSatisfy { "|-: ".contains($0) }
    }

    static func cells(of line: String) -> [String] {
        var parts = line.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.first?.isEmpty == true { parts.removeFirst() }
        if parts.last?.isEmpty == true { parts.removeLast() }
        return parts
    }
}
