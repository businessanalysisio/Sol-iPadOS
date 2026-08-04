import Foundation
import Network

/// Sync status vocabulary — exactly the three chip states of mockup S1.
/// M4 unlocks these (M-02: through M1–M3 the chip only said "Đã lưu cục bộ").
public enum SyncStatus: Equatable {
    case upToDate
    case syncing(pending: Int)
    case offline
}

/// APP-NFR-06: the engine is a swappable protocol — iCloud today, a dedicated
/// backend later, a manual mock in tests — without touching UI.
public protocol SyncEngine: AnyObject {
    var status: SyncStatus { get }
    var onStatusChange: ((SyncStatus) -> Void)? { get set }
    func start()
    func stop()
}

/// Deterministic engine for tests and previews.
public final class ManualSyncEngine: SyncEngine {
    public private(set) var status: SyncStatus
    public var onStatusChange: ((SyncStatus) -> Void)?

    public init(status: SyncStatus = .upToDate) { self.status = status }
    public func start() {}
    public func stop() {}

    public func set(_ new: SyncStatus) {
        status = new
        onStatusChange?(new)
    }
}

/// iCloud engine: NSMetadataQuery counts in-flight ubiquitous items;
/// NWPathMonitor detects offline. The chip never claims "Đã đồng bộ" while
/// either signal says otherwise (G3 / APP-AC-05).
///
/// Layer-1 note (ADR-A03): this class compiles and is logic-reviewed here;
/// its behavioral verification belongs to the Layer-2 e2e pass on real
/// devices — NSMetadataQuery does not fire meaningfully in unit tests.
public final class ICloudSyncEngine: SyncEngine {
    public private(set) var status: SyncStatus = .upToDate {
        didSet { if status != oldValue { onStatusChange?(status) } }
    }
    public var onStatusChange: ((SyncStatus) -> Void)?

    private let query = NSMetadataQuery()
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "vn.io.sol.sync-path")
    private var isOnline = true
    private var pendingCount = 0
    private var observers: [NSObjectProtocol] = []

    public init() {}

    public func start() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                self?.recompute()
            }
        }
        pathMonitor.start(queue: monitorQueue)

        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(
            format: "%K == TRUE OR %K == TRUE",
            NSMetadataUbiquitousItemIsUploadingKey, NSMetadataUbiquitousItemIsDownloadingKey)
        for name in [NSNotification.Name.NSMetadataQueryDidFinishGathering,
                     NSNotification.Name.NSMetadataQueryDidUpdate] {
            observers.append(NotificationCenter.default.addObserver(
                forName: name, object: query, queue: .main) { [weak self] _ in
                    guard let self else { return }
                    self.pendingCount = self.query.resultCount
                    self.recompute()
                })
        }
        query.start()
    }

    public func stop() {
        query.stop()
        pathMonitor.cancel()
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
    }

    private func recompute() {
        if !isOnline { status = .offline }
        else if pendingCount > 0 { status = .syncing(pending: pendingCount) }
        else { status = .upToDate }
    }
}
