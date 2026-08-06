import Foundation

/// Trạng thái backlog item — rawValue là chuỗi canonical trong file .md
/// (khớp nguyên văn workbook: "Not started · In progress · Blocked · Done").
/// UI hiển thị tiếng Việt qua `label`; file luôn giữ chuỗi tiếng Anh để
/// tài liệu tương thích với workbook gốc và mọi app markdown khác.
public enum BacklogStatus: String, CaseIterable, Equatable {
    case notStarted = "Not started"
    case inProgress = "In progress"
    case blocked = "Blocked"
    case done = "Done"

    public var label: String {
        switch self {
        case .notStarted: "Chưa bắt đầu"
        case .inProgress: "Đang làm"
        case .blocked: "Vướng"
        case .done: "Xong"
        }
    }
}

/// Một dòng của bảng Backlog — cột đúng theo workbook, cộng vị trí dòng
/// (`lineIndex`) để mutation chỉ chạm đúng 1 dòng của file.
public struct BacklogItem: Identifiable, Equatable {
    public let id: String            // CM-01 / SM-14 / V-02
    public let track: String         // heading "## " gần nhất phía trên
    public let epic: String
    public let title: String
    public let definitionOfDone: String
    public let deliverableType: String
    public let owner: String
    public let priority: String      // Must / Should / Could (MoSCoW)
    public let effortDays: Int
    public let dependencies: String
    public let sprint: String
    public let status: BacklogStatus
    public let lineIndex: Int
}

/// Parse + mutate tài liệu Backlog. Nguồn sự thật là chính file .md —
/// engine không giữ state riêng, nên Board/Editor/iCloud không bao giờ
/// lệch nhau: ai sửa file thì lần parse sau thấy ngay.
public enum BacklogDocument {
    /// Dòng H1 nhận diện tài liệu Backlog (rename-safe: soi nội dung,
    /// không soi tên file).
    public static let marker = "# BA Bootcamp — Backlog"

    /// Một dòng bảng là "item row" khi ô đầu tiên có dạng ID backlog.
    static func itemID(ofRow cells: [String]) -> String? {
        guard let first = cells.first,
              first.range(of: #"^(CM|SM|V)-\d+$"#, options: .regularExpression) != nil
        else { return nil }
        return first
    }

    /// Tách 1 dòng bảng thành các ô đã trim (bỏ ô rỗng ngoài cùng do `|` mở/đóng).
    static func cells(of line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|") else { return [] }
        var parts = trimmed.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.first == "" { parts.removeFirst() }
        if parts.last == "" { parts.removeLast() }
        return parts
    }

    /// Toàn bộ items theo thứ tự xuất hiện. Dòng bảng thiếu cột hay có ID lạ
    /// thì bỏ qua (file là của người dùng — parse khoan dung, ghi thì phẫu thuật).
    public static func parse(_ text: String) -> [BacklogItem] {
        var items: [BacklogItem] = []
        var track = ""
        for (idx, rawLine) in text.components(separatedBy: "\n").enumerated() {
            if rawLine.hasPrefix("## ") {
                // "Course Materials (35 items · 89d)" → "Course Materials"
                let heading = String(rawLine.dropFirst(3))
                track = heading.components(separatedBy: " (").first ?? heading
                continue
            }
            let c = cells(of: rawLine)
            guard c.count == 11, let id = itemID(ofRow: c),
                  let status = BacklogStatus(rawValue: c[10]) else { continue }
            items.append(BacklogItem(
                id: id, track: track, epic: c[1], title: c[2],
                definitionOfDone: c[3], deliverableType: c[4], owner: c[5],
                priority: c[6], effortDays: Int(c[7]) ?? 0,
                dependencies: c[8], sprint: c[9], status: status,
                lineIndex: idx))
        }
        return items
    }

    /// Đổi Status của đúng 1 item — trả về văn bản mới. Chỉ dòng của item đó
    /// được dựng lại (các ô giữ nguyên, một khoảng trắng quanh `|` như seed);
    /// mọi dòng khác giữ nguyên từng byte. ID không tồn tại → trả nguyên văn.
    public static func settingStatus(in text: String, id: String,
                                     to status: BacklogStatus) -> String {
        var lines = text.components(separatedBy: "\n")
        for (idx, line) in lines.enumerated() {
            var c = cells(of: line)
            guard c.count == 11, itemID(ofRow: c) == id else { continue }
            c[10] = status.rawValue
            lines[idx] = "| " + c.joined(separator: " | ") + " |"
            return lines.joined(separator: "\n")
        }
        return text
    }
}
