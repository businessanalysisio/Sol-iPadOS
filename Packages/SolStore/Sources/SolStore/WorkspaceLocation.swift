import Foundation

/// iCloud availability — APP-FR-15 / APP-AC-09. All four states are modeled;
/// `quotaFull` is surfaced from write errors (quota cannot be pre-flighted).
public enum ICloudStatus: Equatable {
    case available(containerURL: URL)
    case noAccount
    case disabled
    case quotaFull
}

/// Injectable so tests can drive all four states (APP-AC-09).
public protocol UbiquityProviding {
    func status() -> ICloudStatus
}

public struct DefaultUbiquityProvider: UbiquityProviding {
    private let containerID: String?

    public init(containerID: String? = nil) { self.containerID = containerID }

    public func status() -> ICloudStatus {
        guard FileManager.default.ubiquityIdentityToken != nil else { return .noAccount }
        guard let url = FileManager.default.url(forUbiquityContainerIdentifier: containerID) else {
            return .disabled // signed in, but iCloud Drive off for this app
        }
        return .available(containerURL: url.appendingPathComponent("Documents", isDirectory: true))
    }
}

/// Resolves where the workspace lives and migrates local → iCloud on demand.
public struct WorkspaceLocation {
    public enum Backing: Equatable { case iCloud, localFallback(reason: ICloudStatus) }

    public let root: URL
    public let backing: Backing

    /// Picks iCloud when available, otherwise a fully-functional local workspace
    /// (APP-NFR-04: everything single-user works without an iCloud account).
    public static func resolve(ubiquity: UbiquityProviding,
                               localRoot: URL,
                               fileManager: FileManager = .default) throws -> WorkspaceLocation {
        switch ubiquity.status() {
        case .available(let containerURL):
            try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
            return WorkspaceLocation(root: containerURL, backing: .iCloud)
        case let unavailable:
            try fileManager.createDirectory(at: localRoot, withIntermediateDirectories: true)
            return WorkspaceLocation(root: localRoot, backing: .localFallback(reason: unavailable))
        }
    }

    /// Migrates every file from a local workspace into the iCloud container.
    /// PRD v1.2 APP-FR-15 (EMMA-R-03): never overwrite — name collisions in a
    /// non-empty container get the APP-FR-03 numeric suffix (not a conflicted
    /// copy: this is not a sync conflict). Returns migrated (source → dest).
    @discardableResult
    public static func migrate(localRoot: URL, into containerRoot: URL,
                               fileManager: FileManager = .default) throws -> [(from: URL, to: URL)] {
        try fileManager.createDirectory(at: containerRoot, withIntermediateDirectories: true)
        var moves: [(URL, URL)] = []
        let items = try fileManager.contentsOfDirectory(at: localRoot, includingPropertiesForKeys: nil)
        for src in items {
            let dest = FileNaming.collisionFreeURL(
                for: src.lastPathComponent, in: containerRoot, fileManager: fileManager)
            // Copy-then-delete so a mid-migration crash never loses the source (G2).
            try fileManager.copyItem(at: src, to: dest)
            try fileManager.removeItem(at: src)
            moves.append((src, dest))
        }
        return moves
    }
}

/// Name-collision rule — APP-FR-03: suffix " 2", " 3", …; never overwrite silently.
public enum FileNaming {
    public static func collisionFreeURL(for filename: String, in directory: URL,
                                        fileManager: FileManager = .default) -> URL {
        let base = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        func url(_ name: String) -> URL {
            directory.appendingPathComponent(ext.isEmpty ? name : "\(name).\(ext)")
        }
        var candidate = url(base)
        var counter = 2
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = url("\(base) \(counter)")
            counter += 1
        }
        return candidate
    }
}
