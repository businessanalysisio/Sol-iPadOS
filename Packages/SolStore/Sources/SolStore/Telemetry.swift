import Foundation

/// Telemetry — APP-NFR-08, two tiers and ONLY two tiers:
/// - Tier 1 (operational, default ON, user can turn off): the closed set of
///   events below. Every payload field is a number, duration or error code —
///   the schema STRUCTURALLY cannot carry document content, filenames or
///   queries (Tier 2 = never collected, enforced at the type level, not by
///   policy prose).
/// - The toggle takes effect from the NEXT event (AC of APP-FR-16).
public enum TelemetryEvent: Codable, Equatable {
    case syncCompleted(durationMs: Int, errorCode: Int?)
    case journalRecovered
    case conflictResolved
    case crashMarkerFound
    /// Weekly aggregate for the APP-NFR-08 conflicted-copy metric:
    /// N docs with conflicts / M docs that synced — counts only, no identity.
    case weeklyConflictAggregate(conflictedDocs: Int, syncedDocs: Int)

    var name: String {
        switch self {
        case .syncCompleted: "sync_completed"
        case .journalRecovered: "journal_recovered"
        case .conflictResolved: "conflict_resolved"
        case .crashMarkerFound: "crash_marker_found"
        case .weeklyConflictAggregate: "weekly_conflict_aggregate"
        }
    }
}

/// Local, append-only event log. v1 has no upload backend — events stay
/// on-device; the schema and the flag discipline are what ship. Dashboards
/// arrive with the team-workspace phase (v1.1+), inheriting this contract.
public final class TelemetryLog {
    public static let enabledKey = "sol.telemetry.tier1.enabled"

    private let fileURL: URL
    private let defaults: UserDefaults
    private let now: () -> Date

    public init(directory: URL, defaults: UserDefaults = .standard,
                now: @escaping () -> Date = Date.init) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("telemetry.jsonl")
        self.defaults = defaults
        self.now = now
    }

    /// Default ON (Tier 1) — explicit opt-out via Settings (APP-NFR-08).
    public var isEnabled: Bool {
        get { defaults.object(forKey: Self.enabledKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Self.enabledKey) }
    }

    /// Flag is consulted PER EVENT — flipping the toggle affects the very
    /// next call, nothing is buffered around it.
    public func record(_ event: TelemetryEvent) {
        guard isEnabled else { return }
        struct Line: Codable { let at: Date; let name: String; let event: TelemetryEvent }
        guard var data = try? JSONEncoder().encode(Line(at: now(), name: event.name, event: event)) else { return }
        data.append(0x0A)
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: fileURL)
        }
    }

    public func recordedLines() -> [String] {
        guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else { return [] }
        return text.split(separator: "\n").map(String.init)
    }

    /// User-initiated wipe (Settings) — the log is the user's data too.
    public func eraseAll() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
