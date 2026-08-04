import Foundation

/// Vietnamese-aware text normalization for search indexing and querying.
/// PRD v1.2 APP-FR-04 / Phụ lục C: both the index and the query pass through
/// the SAME normalization, so "duong" matches "đường" and NFC/NFD are equivalent.
///
/// SQLite's `unicode61 remove_diacritics` does NOT fold đ/Đ (U+0111/U+0110 are
/// standalone letters, not base+combining mark) — the exact gap PAUL-02 found.
/// We therefore normalize text ourselves and index the normalized form.
public enum VietnameseNormalizer {

    /// Lowercased, diacritic-free, đ→d folded, NFC-stable form.
    public static func fold(_ text: String) -> String {
        // 1. Canonical decomposition so precomposed and combining input converge.
        var s = text.decomposedStringWithCanonicalMapping.lowercased()
        // 2. Strip combining marks (tone/hat/breve live in U+0300…U+036F).
        s = String(String.UnicodeScalarView(s.unicodeScalars.filter { !($0.value >= 0x0300 && $0.value <= 0x036F) }))
        // 3. Fold đ — the one Vietnamese letter that never decomposes into
        //    base+mark (ư/ơ decompose to u/o + U+031B and are handled by step 2).
        s = s.replacingOccurrences(of: "\u{0111}", with: "d")
        return s.precomposedStringWithCanonicalMapping
    }

    /// Builds a prefix-match FTS5 query from free text: each token quoted + `*`.
    public static func ftsQuery(from text: String) -> String {
        fold(text)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { "\"\($0)\"*" }
            .joined(separator: " ")
    }
}
