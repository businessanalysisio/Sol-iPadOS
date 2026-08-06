import XCTest
@testable import SolBootcamp

/// Engine quiz: parse bảng câu hỏi từ section markdown và chấm bài.
final class QuizEngineTests: XCTestCase {
    // MARK: - Parse

    /// Mỗi module seed phải có đúng 1 section quiz 4 câu, mỗi câu 4 phương
    /// án và đáp án hợp lệ — quiz hỏng là shipping bug.
    func testEverySeedModuleQuizParses() throws {
        let moduleBodies = [1: LearnSeed.module1, 2: LearnSeed.module2,
                            3: LearnSeed.module3, 4: LearnSeed.module4,
                            5: LearnSeed.module5]
        let quizzes = CurriculumDocument.parse(LearnSeed.curriculum).filter(\.isQuiz)
        XCTAssertEqual(quizzes.count, 5)
        for quiz in quizzes {
            let n = try XCTUnwrap(quiz.moduleNumber)
            let body = try XCTUnwrap(moduleBodies[n])
            let section = try XCTUnwrap(ModuleDocument.section(for: quiz.id, in: body))
            let questions = QuizTable.parse(section)
            XCTAssertEqual(questions.count, 4, "\(quiz.id) phải có đúng 4 câu")
            XCTAssertEqual(questions.map(\.number), [1, 2, 3, 4])
            for question in questions {
                XCTAssertEqual(question.options.count, 4)
                XCTAssertTrue((0...3).contains(question.answerIndex))
                XCTAssertFalse(question.prompt.isEmpty)
            }
        }
    }

    func testParseSkipsMalformedRows() {
        let text = """
        | # | Câu hỏi | A | B | C | D | Đáp án |
        | --- | --- | --- | --- | --- | --- | --- |
        | 1 | Câu hợp lệ | a | b | c | d | B |
        | x | Số câu lạ | a | b | c | d | A |
        | 2 | Đáp án ngoài A–D | a | b | c | d | E |
        | 3 | Thiếu cột | a | b | c | A |
        """
        let questions = QuizTable.parse(text)
        XCTAssertEqual(questions.count, 1)
        XCTAssertEqual(questions[0].number, 1)
        XCTAssertEqual(questions[0].answerIndex, 1)
    }

    /// Quiz table nằm trong section quiz — parse toàn tài liệu module cũng
    /// chỉ được đúng 4 câu (không dòng nào khác lọt lưới).
    func testParseWholeModuleDocumentFindsOnlyQuizRows() {
        XCTAssertEqual(QuizTable.parse(LearnSeed.module1).count, 4)
    }

    // MARK: - Grade

    func testGradeCountsCorrectAnswersOnly() {
        let questions = QuizTable.parse(
            ModuleDocument.section(for: "L1-05", in: LearnSeed.module1)!)
        // Đáp án đúng của quiz Module 1: B, C, C, A.
        let perfect = QuizTable.grade(questions, answers: [1, 2, 2, 0])
        XCTAssertEqual(perfect, QuizGrade(correct: 4, total: 4))
        XCTAssertTrue(perfect.passed)

        let boundary = QuizTable.grade(questions, answers: [1, 2, 2, 3])
        XCTAssertEqual(boundary.correct, 3)
        XCTAssertTrue(boundary.passed, "3/4 = 75% ≥ ngưỡng 70%")

        let failing = QuizTable.grade(questions, answers: [0, 0, 0, 1])
        XCTAssertEqual(failing.correct, 0)
        XCTAssertFalse(failing.passed)
    }

    func testGradeTreatsUnansweredAsWrong() {
        let questions = QuizTable.parse(
            ModuleDocument.section(for: "L1-05", in: LearnSeed.module1)!)
        let grade = QuizTable.grade(questions, answers: [1, nil])
        XCTAssertEqual(grade, QuizGrade(correct: 1, total: 4))
        XCTAssertFalse(grade.passed)
    }

    func testEmptyQuizNeverPasses() {
        XCTAssertFalse(QuizGrade(correct: 0, total: 0).passed)
    }
}
