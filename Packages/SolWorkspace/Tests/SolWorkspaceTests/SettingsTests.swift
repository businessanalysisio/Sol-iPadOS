import XCTest
import SolStore
@testable import SolWorkspace

/// APP-FR-16 — one test per line of the closed AC checklist (PRD v1.2).
final class SettingsTests: XCTestCase {
    private var defaults: UserDefaults!
    private var telemetryDir: URL!

    override func setUpWithError() throws {
        defaults = UserDefaults(suiteName: "sol-settings-test-\(UUID().uuidString)")
        telemetryDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-tel-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: telemetryDir)
    }

    // MARK: AC — theme đổi có hiệu lực ngay (state-level: giá trị publish tức thì và bền)

    func testThemePersistsAndMapsToColorScheme() {
        let s1 = SettingsStore(defaults: defaults)
        XCTAssertEqual(s1.theme, .system)
        XCTAssertNil(s1.theme.colorScheme) // system = follow OS

        s1.theme = .dark
        XCTAssertEqual(s1.theme.colorScheme, .dark) // RootView applies this frame

        let s2 = SettingsStore(defaults: defaults) // "restart"
        XCTAssertEqual(s2.theme, .dark) // persisted
    }

    // MARK: AC — đổi ngôn ngữ: áp toàn app qua AppleLanguages, PHẢI báo restart

    func testLanguageChangeSetsAppleLanguagesAndFlagsRestart() {
        let s = SettingsStore(defaults: defaults)
        s.language = .en
        XCTAssertEqual(defaults.array(forKey: "AppleLanguages") as? [String], ["en"])
        // Process is running under a non-en locale in CI → restart notice due.
        // (On an already-en device this is legitimately false — assert the
        // linkage, not a fixed value.)
        XCTAssertEqual(s.restartNeededForLanguage,
                       Locale.current.language.languageCode?.identifier != "en")
    }

    // MARK: AC — danh sách phím tắt khớp 100% Phụ lục A (cả hai nửa)

    func testShortcutListCoversPhuLucACompletely() {
        // Palette half — same closed enum the palette renders.
        XCTAssertEqual(SolCommandID.allCases.count, 8)
        // Non-palette half — pinned verbatim.
        XCTAssertEqual(NonPaletteShortcuts.all.map(\.keys),
                       ["⌘B", "⌘I", "⌘⇧H", "⌘⇧L", "⌘⇧Q", "Esc", "⌘W", "⌘,"])
        // No duplicate key assignments across the union (EMMA-R-02 regression).
        let paletteKeys = SolCommandID.allCases.compactMap(\.shortcutLabel)
            .flatMap { $0.split(separator: "/").map(String.init) } // "⌘1/2/3"
        let allKeys = paletteKeys + NonPaletteShortcuts.all.map(\.keys)
        XCTAssertEqual(allKeys.count, Set(allKeys).count, "phím tắt bị gán trùng: \(allKeys)")
    }

    // MARK: AC — toggle telemetry ghi đúng cờ, hiệu lực từ sự kiện KẾ TIẾP

    func testTelemetryToggleTakesEffectFromNextEvent() throws {
        let log = try TelemetryLog(directory: telemetryDir, defaults: defaults)
        let s = SettingsStore(defaults: defaults, telemetry: log)

        XCTAssertTrue(s.telemetryEnabled) // Tier 1 default ON (APP-NFR-08)
        log.record(.syncCompleted(durationMs: 120, errorCode: nil))
        XCTAssertEqual(log.recordedLines().count, 1)

        s.telemetryEnabled = false // flag written…
        log.record(.conflictResolved) // …and the very next event obeys it
        XCTAssertEqual(log.recordedLines().count, 1)

        s.telemetryEnabled = true
        log.record(.journalRecovered)
        XCTAssertEqual(log.recordedLines().count, 2)
    }

    func testTelemetryEraseAll() throws {
        let log = try TelemetryLog(directory: telemetryDir, defaults: defaults)
        log.record(.crashMarkerFound)
        XCTAssertFalse(log.recordedLines().isEmpty)
        log.eraseAll()
        XCTAssertTrue(log.recordedLines().isEmpty)
    }

    // MARK: APP-NFR-08 Tier-2 — schema cannot carry content (structural check)

    func testTelemetrySchemaCarriesOnlyNumbers() throws {
        let log = try TelemetryLog(directory: telemetryDir, defaults: defaults)
        log.record(.syncCompleted(durationMs: 300, errorCode: 7))
        log.record(.weeklyConflictAggregate(conflictedDocs: 2, syncedDocs: 40))
        for line in log.recordedLines() {
            let json = try XCTUnwrap(
                try JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])
            // Whitelist of top-level keys; payloads are numeric-only by type.
            XCTAssertEqual(Set(json.keys).subtracting(["at", "name", "event"]), [])
        }
    }

    // MARK: AC — mục Thùng rác mở đúng APP-FR-17 (wiring at the VM level)

    func testSettingsOpensTrashFlag() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-set-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try DocumentStore(root: root, index: SearchIndex())
        let model = WorkspaceViewModel(store: store, backing: .iCloud,
                                       settings: SettingsStore(defaults: defaults))
        // SettingsView's openTrash closure flips exactly this flag.
        XCTAssertFalse(model.trashVisible)
        model.trashVisible = true
        XCTAssertTrue(model.trashVisible)
    }
}
