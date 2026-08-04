import Foundation
import GRDB

/// FTS5 full-text index — APP-FR-04. Indexes VietnameseNormalizer-folded text,
/// so diacritic-free queries match ("dac ta" → "đặc tả", "duong" → "đường").
/// Purge cascade (APP-BR-04): `remove(docID:)` is called by DocumentStore on purge.
public final class SearchIndex {
    private let dbQueue: DatabaseQueue

    public init(databaseURL: URL) throws {
        dbQueue = try DatabaseQueue(path: databaseURL.path)
        try dbQueue.write { db in
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS doc_fts USING fts5(
                    doc_id UNINDEXED, title, body, tokenize='unicode61'
                )
                """)
        }
    }

    /// In-memory index for tests.
    public init() throws {
        dbQueue = try DatabaseQueue()
        try dbQueue.write { db in
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS doc_fts USING fts5(
                    doc_id UNINDEXED, title, body, tokenize='unicode61'
                )
                """)
        }
    }

    /// Insert-or-replace a document. Called on save — the search-ready clock
    /// (APP-AC-02 ≤ 5s) starts at "Đã lưu cục bộ" and ends here.
    public func index(docID: String, title: String, body: String) throws {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM doc_fts WHERE doc_id = ?", arguments: [docID])
            try db.execute(
                sql: "INSERT INTO doc_fts (doc_id, title, body) VALUES (?, ?, ?)",
                arguments: [docID, VietnameseNormalizer.fold(title), VietnameseNormalizer.fold(body)])
        }
    }

    public func remove(docID: String) throws {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM doc_fts WHERE doc_id = ?", arguments: [docID])
        }
    }

    /// Ranked doc IDs for a free-text query (prefix matching per token).
    public func search(_ text: String) throws -> [String] {
        let query = VietnameseNormalizer.ftsQuery(from: text)
        guard !query.isEmpty else { return [] }
        return try dbQueue.read { db in
            try String.fetchAll(db, sql: """
                SELECT doc_id FROM doc_fts WHERE doc_fts MATCH ?
                ORDER BY bm25(doc_fts)
                """, arguments: [query])
        }
    }

    /// True if the doc has an index row — used by purge-cascade tests (APP-AC-08).
    public func contains(docID: String) throws -> Bool {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM doc_fts WHERE doc_id = ?",
                             arguments: [docID]) ?? 0 > 0
        }
    }
}
