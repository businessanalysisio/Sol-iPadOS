import SwiftUI

/// PRD v1.2 Phụ lục A — the CLOSED v1 command list. Adding a command here
/// without amending the PRD is a spec violation (the list is part of the
/// acceptance criteria of APP-FR-05: "100% lệnh trong Phụ lục A thực thi đúng").
public enum SolCommandID: String, CaseIterable, Identifiable {
    case insertTable        // ⌘⇧T  (editor — enabled in M2)
    case insertDataBlock    // ⌘⇧D  (editor — enabled in M3)
    case exportSnapshot     //      (APP-FR-12 — enabled in M2)
    case newDocument        // ⌘N
    case paneMode           // ⌘1/2/3 (editor — enabled in M2)
    case findInDocument     // ⌘F   (editor — enabled in M2)
    case findInWorkspace    // ⌘⇧F
    case openTrash

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .insertTable: "Chèn bảng"
        case .insertDataBlock: "Chèn sol-data block"
        case .exportSnapshot: "Xuất snapshot"
        case .newDocument: "Tài liệu mới"
        case .paneMode: "Chuyển chế độ pane"
        case .findInDocument: "Tìm trong tài liệu"
        case .findInWorkspace: "Tìm trong workspace"
        case .openTrash: "Mở Thùng rác"
        }
    }

    public var shortcutLabel: String? {
        switch self {
        case .insertTable: "⌘⇧T"
        case .insertDataBlock: "⌘⇧D"
        case .exportSnapshot: nil
        case .newDocument: "⌘N"
        case .paneMode: "⌘1/2/3"
        case .findInDocument: "⌘F"
        case .findInWorkspace: "⌘⇧F"
        case .openTrash: nil
        }
    }

    /// Commands whose target ships in a later milestone stay visible but
    /// disabled — the closed list renders in full from M1 (G3: trung thực).
    public var availableInM1: Bool {
        switch self {
        case .newDocument, .findInWorkspace, .openTrash: true
        case .insertTable, .insertDataBlock, .exportSnapshot, .paneMode, .findInDocument: false
        }
    }
}
