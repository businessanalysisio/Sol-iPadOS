import Foundation
import Observation
import SolStore

/// View-model của Bootcamp Learn: đọc Curriculum từ DocumentStore, đổi trạng
/// thái bài học / ghi điểm quiz bằng mutation phẫu thuật trên chính file .md.
///
/// Ghi file theo đúng bất biến G2 (journal-before-write) như Bootcamp Board:
/// journal ghi nhận TRƯỚC, save sau, clear cuối — kill app giữa chừng không
/// mất gì. Mỗi lần ghi cũng tạo 1 version (APP-FR-12) kể được "ai, lúc nào".
@Observable
public final class LearnViewModel {
    public struct ModuleSection: Identifiable {
        public var id: String { name }
        public let name: String       // "Module 1 · Foundations & Business Thinking"
        public let lessons: [Lesson]
    }

    public private(set) var sections: [ModuleSection] = []
    public private(set) var totalLessons = 0
    public private(set) var doneLessons = 0
    public private(set) var totalMinutes = 0
    public private(set) var doneMinutes = 0
    public var errorMessage: String?

    private let store: DocumentStore
    private let actor: String
    private var curriculumDoc: Document?

    public init(store: DocumentStore, actor: String = "iPad") {
        self.store = store
        self.actor = actor
        reload()
    }

    /// Tìm tài liệu Curriculum theo dòng H1 (rename-safe) — cùng khẩu vị
    /// BootcampBoardViewModel.backlogDocument.
    public static func curriculumDocument(in store: DocumentStore) -> Document? {
        (try? store.listDocuments())?.first { doc in
            (try? store.contents(of: doc))?.hasPrefix(CurriculumDocument.marker) == true
        }
    }

    public var progress: Double {
        totalLessons == 0 ? 0 : Double(doneLessons) / Double(totalLessons)
    }

    /// Bài cho nút "Tiếp tục học" — bài đầu tiên chưa Xong theo thứ tự
    /// giáo trình; nil khi đã hoàn thành tất cả.
    public var continueLesson: Lesson? {
        sections.flatMap(\.lessons).first { $0.status != .done }
    }

    /// Bản sống của một bài học (màn chi tiết tra theo ID để không đọc
    /// dữ liệu cũ sau khi status/score đổi).
    public func lesson(id: String) -> Lesson? {
        sections.flatMap(\.lessons).first { $0.id == id }
    }

    public func reload() {
        curriculumDoc = Self.curriculumDocument(in: store)
        guard let doc = curriculumDoc, let text = try? store.contents(of: doc) else {
            sections = []
            totalLessons = 0; doneLessons = 0; totalMinutes = 0; doneMinutes = 0
            return
        }
        let lessons = CurriculumDocument.parse(text)
        var names: [String] = []
        var byModule: [String: [Lesson]] = [:]
        for lesson in lessons {
            if byModule[lesson.module] == nil { names.append(lesson.module) }
            byModule[lesson.module, default: []].append(lesson)
        }
        sections = names.map { ModuleSection(name: $0, lessons: byModule[$0] ?? []) }
        totalLessons = lessons.count
        doneLessons = lessons.filter { $0.status == .done }.count
        totalMinutes = lessons.reduce(0) { $0 + $1.durationMinutes }
        doneMinutes = lessons.filter { $0.status == .done }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    /// Đổi trạng thái 1 bài học — sửa đúng 1 dòng của Curriculum.
    public func setStatus(_ status: LessonStatus, for id: String) {
        mutateCurriculum { CurriculumDocument.settingStatus(in: $0, id: id, to: status) }
    }

    /// Chấm + ghi kết quả quiz vào bảng Curriculum (Score = "đúng/tổng",
    /// đạt ngưỡng thì Done). Trả về điểm để UI hiển thị ngay.
    @discardableResult
    public func submitQuiz(answers: [Int?], for lesson: Lesson) -> QuizGrade? {
        let questions = quizQuestions(for: lesson)
        guard !questions.isEmpty else { return nil }
        let grade = QuizTable.grade(questions, answers: answers)
        mutateCurriculum {
            CurriculumDocument.recordingQuizResult(in: $0, id: lesson.id,
                                                   correct: grade.correct,
                                                   total: grade.total)
        }
        return grade
    }

    /// Tài liệu module chứa nội dung bài học — để "Mở trong Editor" đọc bản
    /// đầy đủ qua pipeline M2 thật.
    public func moduleDocument(for lesson: Lesson) -> Document? {
        guard let n = lesson.moduleNumber else { return nil }
        return (try? store.listDocuments())?.first { doc in
            (try? store.contents(of: doc))?
                .hasPrefix(ModuleDocument.marker(forModule: n)) == true
        }
    }

    /// Lát nội dung markdown của bài học trong tài liệu module.
    public func lessonBody(for lesson: Lesson) -> String? {
        guard let doc = moduleDocument(for: lesson),
              let text = try? store.contents(of: doc) else { return nil }
        return ModuleDocument.section(for: lesson.id, in: text)
    }

    /// Câu hỏi của một dòng Quiz — parse từ section quiz trong tài liệu module.
    public func quizQuestions(for lesson: Lesson) -> [QuizQuestion] {
        guard lesson.isQuiz, let body = lessonBody(for: lesson) else { return [] }
        return QuizTable.parse(body)
    }

    // MARK: - Private

    private func mutateCurriculum(_ transform: (String) -> String) {
        guard let doc = curriculumDoc, let text = try? store.contents(of: doc) else { return }
        let updated = transform(text)
        guard updated != text else { return }
        do {
            try store.journal.recordPending(docID: doc.id, content: updated)
            try store.save(doc, contents: updated)
            store.journal.clearPending(docID: doc.id)
            try store.versions.record(docID: doc.id, content: updated,
                                      actor: actor, operation: .edit)
            errorMessage = nil
        } catch {
            errorMessage = "Không lưu được thay đổi — journal vẫn giữ nội dung."
        }
        reload()
    }
}
