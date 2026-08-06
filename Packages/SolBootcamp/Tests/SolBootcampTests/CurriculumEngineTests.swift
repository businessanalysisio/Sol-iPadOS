import XCTest
@testable import SolBootcamp

/// Engine thuần: parse Curriculum từ .md, mutation phẫu thuật status/score,
/// trích section bài học từ tài liệu module.
final class CurriculumEngineTests: XCTestCase {
    // MARK: - Parse

    func testParseSeedCurriculumMatchesSyllabus() {
        let lessons = CurriculumDocument.parse(LearnSeed.curriculum)
        XCTAssertEqual(lessons.count, 29, "24 bài học + 5 quiz")
        XCTAssertEqual(lessons.reduce(0) { $0 + $1.durationMinutes }, 970)
        XCTAssertEqual(lessons.filter(\.isQuiz).count, 5)

        // 5 module đúng thứ tự giáo trình, số mục mỗi module đúng syllabus.
        var moduleNames: [String] = []
        for lesson in lessons where !moduleNames.contains(lesson.module) {
            moduleNames.append(lesson.module)
        }
        XCTAssertEqual(moduleNames, [
            "Module 1 · Foundations & Business Thinking",
            "Module 2 · Discovery & Requirements",
            "Module 3 · Analysis & Solution Design",
            "Module 4 · Implementation, Data & Validation",
            "Module 5 · Capstone & Career Launch",
        ])
        XCTAssertEqual(moduleNames.map { name in
            lessons.filter { $0.module == name }.count
        }, [5, 7, 7, 5, 5])

        // Kiểm tra chéo 1 dòng đầy đủ.
        let l304 = lessons.first { $0.id == "L3-04" }!
        XCTAssertEqual(l304.week, "Wk 7")
        XCTAssertEqual(l304.title, "SQL cơ bản cho BA")
        XCTAssertEqual(l304.type, "Video")
        XCTAssertEqual(l304.durationMinutes, 45)
        XCTAssertEqual(l304.status, .notStarted)
        XCTAssertEqual(l304.score, "—")
        XCTAssertEqual(l304.moduleNumber, 3)

        // Mọi mục seed đều Not started, chưa có điểm.
        XCTAssertTrue(lessons.allSatisfy { $0.status == .notStarted && $0.score == "—" })
    }

    // MARK: - Mutation

    func testSettingStatusTouchesExactlyOneLine() {
        let original = LearnSeed.curriculum
        let updated = CurriculumDocument.settingStatus(in: original, id: "L1-01",
                                                       to: .done)
        let before = original.components(separatedBy: "\n")
        let after = updated.components(separatedBy: "\n")
        XCTAssertEqual(before.count, after.count)
        let changed = zip(before, after).filter { $0 != $1 }
        XCTAssertEqual(changed.count, 1, "mutation phải là phẫu thuật — đúng 1 dòng")
        XCTAssertTrue(changed[0].1.hasPrefix("| L1-01 |"))

        let lessons = CurriculumDocument.parse(updated)
        XCTAssertEqual(lessons.first { $0.id == "L1-01" }?.status, .done)
        XCTAssertEqual(lessons.filter { $0.status == .notStarted }.count, 28)
    }

    func testRecordingQuizResultPassMarksDoneWithScore() {
        let updated = CurriculumDocument.recordingQuizResult(
            in: LearnSeed.curriculum, id: "L1-05", correct: 3, total: 4)
        let quiz = CurriculumDocument.parse(updated).first { $0.id == "L1-05" }!
        XCTAssertEqual(quiz.status, .done, "3/4 = 75% ≥ ngưỡng 70%")
        XCTAssertEqual(quiz.score, "3/4")
    }

    func testRecordingQuizResultFailKeepsInProgressWithScore() {
        let updated = CurriculumDocument.recordingQuizResult(
            in: LearnSeed.curriculum, id: "L1-05", correct: 2, total: 4)
        let quiz = CurriculumDocument.parse(updated).first { $0.id == "L1-05" }!
        XCTAssertEqual(quiz.status, .inProgress,
                       "2/4 = 50% dưới ngưỡng — giữ Đang học để làm lại")
        XCTAssertEqual(quiz.score, "2/4")
    }

    func testMutationUnknownIDReturnsTextUnchanged() {
        let text = LearnSeed.curriculum
        XCTAssertEqual(CurriculumDocument.settingStatus(in: text, id: "L9-99",
                                                        to: .done), text)
        XCTAssertEqual(CurriculumDocument.recordingQuizResult(in: text, id: "L9-99",
                                                              correct: 4, total: 4), text)
    }

    // MARK: - Module sections

    /// Bất biến chéo của bộ seed: mỗi dòng trong Curriculum phải có đúng
    /// section "## <id> · …" trong tài liệu module tương ứng — một bài học
    /// không có nội dung là shipping bug.
    func testEveryLessonHasASectionInItsModuleDocument() throws {
        let moduleBodies = [1: LearnSeed.module1, 2: LearnSeed.module2,
                            3: LearnSeed.module3, 4: LearnSeed.module4,
                            5: LearnSeed.module5]
        for lesson in CurriculumDocument.parse(LearnSeed.curriculum) {
            let n = try XCTUnwrap(lesson.moduleNumber)
            let body = try XCTUnwrap(moduleBodies[n])
            XCTAssertTrue(body.hasPrefix(ModuleDocument.marker(forModule: n)))
            let section = ModuleDocument.section(for: lesson.id, in: body)
            XCTAssertNotNil(section, "\(lesson.id) thiếu section trong Module \(n)")
            XCTAssertTrue(section?.hasPrefix("## \(lesson.id) ·") == true)
        }
    }

    func testSectionStopsAtNextLessonHeading() {
        let section = ModuleDocument.section(for: "L1-01", in: LearnSeed.module1)!
        XCTAssertTrue(section.contains("### Action"),
                      "sub-heading ### thuộc về section, không được cắt")
        XCTAssertFalse(section.contains("## L1-02"),
                       "section phải dừng trước bài kế tiếp")
    }
}
