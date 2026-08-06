import Foundation

/// Trạng thái bài học — rawValue là chuỗi canonical trong file .md
/// (cùng khẩu vị BacklogStatus: file giữ tiếng Anh để tương thích mọi app
/// markdown khác; UI hiển thị tiếng Việt qua `label`).
public enum LessonStatus: String, CaseIterable, Equatable {
    case notStarted = "Not started"
    case inProgress = "In progress"
    case done = "Done"

    public var label: String {
        switch self {
        case .notStarted: "Chưa học"
        case .inProgress: "Đang học"
        case .done: "Xong"
        }
    }
}

/// Một dòng của bảng Curriculum — giáo trình 12 tuần của BA Bootcamp,
/// cộng vị trí dòng (`lineIndex`) để mutation chỉ chạm đúng 1 dòng của file.
public struct Lesson: Identifiable, Hashable {
    public let id: String            // L1-01 … L5-05
    public let module: String        // heading "## " gần nhất phía trên
    public let week: String          // "Wk 1" … "Wk 12"
    public let title: String
    public let objective: String
    public let type: String          // Video / Reading / Exercise / Quiz
    public let durationMinutes: Int
    public let status: LessonStatus
    public let score: String         // "—" khi chưa làm quiz, "3/4" sau khi nộp
    public let lineIndex: Int

    /// Dòng Quiz mở giao diện làm bài thay vì nội dung bài học.
    public var isQuiz: Bool { type == "Quiz" }

    /// Số module lấy từ ID (L3-02 → 3) — khớp tài liệu "Module N · …".
    public var moduleNumber: Int? {
        Int(id.dropFirst().prefix(while: { $0 != "-" }))
    }
}

/// Parse + mutate tài liệu Curriculum. Nguồn sự thật là chính file .md —
/// engine không giữ state riêng (cùng nguyên tắc BacklogDocument), nên
/// Learn/Editor/iCloud không bao giờ lệch nhau.
public enum CurriculumDocument {
    /// Dòng H1 nhận diện tài liệu Curriculum (rename-safe: soi nội dung,
    /// không soi tên file).
    public static let marker = "# BA Bootcamp — Curriculum"

    /// Ngưỡng đạt quiz — đúng ≥ 70% thì dòng quiz tính là Xong.
    public static let passRatio = 0.7

    /// Một dòng bảng là "lesson row" khi ô đầu tiên có dạng ID bài học.
    static func lessonID(ofRow cells: [String]) -> String? {
        guard let first = cells.first,
              first.range(of: #"^L\d+-\d+$"#, options: .regularExpression) != nil
        else { return nil }
        return first
    }

    /// Toàn bộ bài học theo thứ tự giáo trình. Dòng bảng thiếu cột hay có
    /// ID/Status lạ thì bỏ qua (parse khoan dung, ghi thì phẫu thuật).
    public static func parse(_ text: String) -> [Lesson] {
        var lessons: [Lesson] = []
        var module = ""
        for (idx, rawLine) in text.components(separatedBy: "\n").enumerated() {
            if rawLine.hasPrefix("## ") {
                // "Module 1 · Foundations & Business Thinking (Wk 1–2)" → bỏ "(…)"
                let heading = String(rawLine.dropFirst(3))
                module = heading.components(separatedBy: " (").first ?? heading
                continue
            }
            let c = BacklogDocument.cells(of: rawLine)
            guard c.count == 8, let id = lessonID(ofRow: c),
                  let status = LessonStatus(rawValue: c[6]) else { continue }
            lessons.append(Lesson(
                id: id, module: module, week: c[1], title: c[2], objective: c[3],
                type: c[4], durationMinutes: Int(c[5]) ?? 0,
                status: status, score: c[7], lineIndex: idx))
        }
        return lessons
    }

    /// Đổi Status của đúng 1 bài học — trả về văn bản mới; ID không tồn tại
    /// → trả nguyên văn.
    public static func settingStatus(in text: String, id: String,
                                     to status: LessonStatus) -> String {
        mutatingRow(in: text, id: id) { $0[6] = status.rawValue }
    }

    /// Ghi kết quả quiz: Score = "đúng/tổng"; đạt ngưỡng thì Done, chưa đạt
    /// giữ In progress để học viên ôn lại và làm lại.
    public static func recordingQuizResult(in text: String, id: String,
                                           correct: Int, total: Int) -> String {
        mutatingRow(in: text, id: id) { c in
            c[6] = (total > 0 && Double(correct) / Double(total) >= passRatio)
                ? LessonStatus.done.rawValue : LessonStatus.inProgress.rawValue
            c[7] = "\(correct)/\(total)"
        }
    }

    /// Dựng lại đúng 1 dòng của bảng (các ô giữ nguyên trừ ô được đổi, một
    /// khoảng trắng quanh `|` như seed); mọi dòng khác giữ nguyên từng byte.
    private static func mutatingRow(in text: String, id: String,
                                    _ change: (inout [String]) -> Void) -> String {
        var lines = text.components(separatedBy: "\n")
        for (idx, line) in lines.enumerated() {
            var c = BacklogDocument.cells(of: line)
            guard c.count == 8, lessonID(ofRow: c) == id else { continue }
            change(&c)
            lines[idx] = "| " + c.joined(separator: " | ") + " |"
            return lines.joined(separator: "\n")
        }
        return text
    }
}

/// Tài liệu nội dung module ("# BA Bootcamp — Module N · …"): mỗi bài học là
/// một section "## L1-01 · …" — trích đúng lát nội dung cho màn bài học.
public enum ModuleDocument {
    /// Tiền tố H1 nhận diện tài liệu module N (rename-safe).
    public static func marker(forModule n: Int) -> String {
        "# BA Bootcamp — Module \(n) ·"
    }

    /// Section của một bài học: từ heading "## <id> ·" đến trước "## " kế
    /// tiếp (sub-heading "### " thuộc về section, không cắt).
    public static func section(for lessonID: String, in text: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        guard let start = lines.firstIndex(where: {
            $0.hasPrefix("## \(lessonID) ·") || $0 == "## \(lessonID)"
        }) else { return nil }
        var end = lines.count
        for i in (start + 1)..<lines.count where lines[i].hasPrefix("## ") {
            end = i
            break
        }
        return lines[start..<end].joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
