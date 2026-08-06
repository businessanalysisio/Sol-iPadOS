import XCTest
import SolStore
@testable import SolBootcamp

/// Learn ↔ DocumentStore: discovery, tiến độ, ghi status/score đúng bất biến
/// journal-before-write, và luồng quiz end-to-end trên file thật.
final class LearnViewModelTests: XCTestCase {
    private var root: URL!
    private var store: DocumentStore!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sol-learn-\(UUID().uuidString)", isDirectory: true)
        store = try DocumentStore(root: root, index: SearchIndex())
        _ = try LearnSeed.installIfNeeded(into: store)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testDiscoversCurriculumAndComputesTotals() {
        let model = LearnViewModel(store: store)
        XCTAssertEqual(model.totalLessons, 29)
        XCTAssertEqual(model.totalMinutes, 970)
        XCTAssertEqual(model.doneLessons, 0)
        XCTAssertEqual(model.sections.count, 5)
        XCTAssertEqual(model.progress, 0)
        XCTAssertEqual(model.continueLesson?.id, "L1-01",
                       "chưa học gì thì tiếp tục = bài đầu tiên")
    }

    func testSetStatusWritesCurriculumWithJournalInvariant() throws {
        let model = LearnViewModel(store: store, actor: "iPad-Test")
        model.setStatus(.done, for: "L1-01")

        // Curriculum trên đĩa đã đổi đúng dòng; model phản ánh ngay.
        let curriculum = try XCTUnwrap(LearnViewModel.curriculumDocument(in: store))
        XCTAssertEqual(CurriculumDocument.parse(try store.contents(of: curriculum))
            .first { $0.id == "L1-01" }?.status, .done)
        XCTAssertEqual(model.doneLessons, 1)
        XCTAssertEqual(model.doneMinutes, 25)

        // Journal-before-write đã hoàn tất chu trình: pending phải sạch.
        XCTAssertNil(store.journal.pending(docID: curriculum.id))
        // Version APP-FR-12: có bản ghi actor/operation cho lần ghi.
        let versions = try store.versions.list(docID: curriculum.id) // newest-first
        XCTAssertEqual(versions.first?.actor, "iPad-Test")
        XCTAssertEqual(versions.first?.operation, .edit)

        // "Tiếp tục học" nhảy sang bài kế tiếp.
        XCTAssertEqual(model.continueLesson?.id, "L1-02")
    }

    func testLessonBodyComesFromModuleDocument() throws {
        let model = LearnViewModel(store: store)
        let lesson = try XCTUnwrap(model.lesson(id: "L3-04"))
        let doc = try XCTUnwrap(model.moduleDocument(for: lesson))
        XCTAssertTrue(try store.contents(of: doc)
            .hasPrefix(ModuleDocument.marker(forModule: 3)))
        let body = try XCTUnwrap(model.lessonBody(for: lesson))
        XCTAssertTrue(body.hasPrefix("## L3-04 ·"))
        XCTAssertTrue(body.contains("### Action"))
    }

    func testSubmitQuizPassWritesScoreAndDone() throws {
        let model = LearnViewModel(store: store)
        let quiz = try XCTUnwrap(model.lesson(id: "L1-05"))
        XCTAssertEqual(model.quizQuestions(for: quiz).count, 4)

        // Đáp án đúng của quiz Module 1: B, C, C, A.
        let grade = try XCTUnwrap(model.submitQuiz(answers: [1, 2, 2, 0], for: quiz))
        XCTAssertEqual(grade, QuizGrade(correct: 4, total: 4))
        XCTAssertTrue(grade.passed)

        // Kết quả nằm trong chính file Curriculum — model và đĩa cùng thấy.
        let updated = try XCTUnwrap(model.lesson(id: "L1-05"))
        XCTAssertEqual(updated.status, .done)
        XCTAssertEqual(updated.score, "4/4")
        let curriculum = try XCTUnwrap(LearnViewModel.curriculumDocument(in: store))
        XCTAssertTrue(try store.contents(of: curriculum).contains("| Done | 4/4 |"))
    }

    func testSubmitQuizFailKeepsInProgressForRetake() throws {
        let model = LearnViewModel(store: store)
        let quiz = try XCTUnwrap(model.lesson(id: "L1-05"))
        let grade = try XCTUnwrap(model.submitQuiz(answers: [0, 0, 0, 1], for: quiz))
        XCTAssertFalse(grade.passed)

        let updated = try XCTUnwrap(model.lesson(id: "L1-05"))
        XCTAssertEqual(updated.status, .inProgress,
                       "trượt thì giữ Đang học để ôn và làm lại")
        XCTAssertEqual(updated.score, "0/4")

        // Làm lại và đạt: điểm mới ghi đè điểm cũ.
        _ = model.submitQuiz(answers: [1, 2, 2, 0], for: quiz)
        XCTAssertEqual(model.lesson(id: "L1-05")?.score, "4/4")
        XCTAssertEqual(model.lesson(id: "L1-05")?.status, .done)
    }

    func testSubmitQuizOnNonQuizLessonIsRefused() throws {
        let model = LearnViewModel(store: store)
        let reading = try XCTUnwrap(model.lesson(id: "L1-01"))
        XCTAssertNil(model.submitQuiz(answers: [0], for: reading),
                     "bài thường không có câu hỏi — không được ghi gì")
        XCTAssertEqual(model.lesson(id: "L1-01")?.score, "—")
    }

    func testMissingCurriculumIsSafeNoop() throws {
        for doc in try store.listDocuments() { try store.softDelete(doc) }
        let model = LearnViewModel(store: store)
        XCTAssertEqual(model.totalLessons, 0)
        XCTAssertNil(model.continueLesson)
        model.setStatus(.done, for: "L1-01") // không crash, không tạo gì
        XCTAssertTrue(try store.listDocuments().isEmpty)
    }
}
