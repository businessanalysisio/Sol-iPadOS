import Foundation

/// Một câu hỏi trắc nghiệm — dòng bảng
/// `| # | Câu hỏi | A | B | C | D | Đáp án |` trong section quiz của tài
/// liệu module. Quiz vẫn là markdown thường (APP-FR-10): đọc được ở mọi
/// app, sửa được trong Editor; Learn chỉ thêm giao diện làm bài lên trên.
public struct QuizQuestion: Identifiable, Hashable {
    public var id: Int { number }
    public let number: Int
    public let prompt: String
    public let options: [String]     // đúng 4 phương án theo cột A–D
    public let answerIndex: Int      // 0–3

    public init(number: Int, prompt: String, options: [String], answerIndex: Int) {
        self.number = number
        self.prompt = prompt
        self.options = options
        self.answerIndex = answerIndex
    }
}

/// Kết quả một lần nộp quiz.
public struct QuizGrade: Equatable {
    public let correct: Int
    public let total: Int

    public init(correct: Int, total: Int) {
        self.correct = correct
        self.total = total
    }

    /// Đạt khi đúng ≥ ngưỡng chung của giáo trình (70%).
    public var passed: Bool {
        total > 0 && Double(correct) / Double(total) >= CurriculumDocument.passRatio
    }
}

/// Parse + chấm bảng quiz. Không giữ state — câu hỏi và đáp án sống trong
/// chính file .md của module.
public enum QuizTable {
    static let answerLetters = ["A", "B", "C", "D"]

    /// Parse mọi dòng bảng dạng quiz trong đoạn văn bản (thường là section
    /// của dòng Quiz). Dòng thiếu cột, số câu lạ hay đáp án ngoài A–D thì
    /// bỏ qua — parse khoan dung như mọi engine khác.
    public static func parse(_ text: String) -> [QuizQuestion] {
        var questions: [QuizQuestion] = []
        for line in text.components(separatedBy: "\n") {
            let c = BacklogDocument.cells(of: line)
            guard c.count == 7, let number = Int(c[0]),
                  let answer = answerLetters.firstIndex(of: c[6]) else { continue }
            questions.append(QuizQuestion(number: number, prompt: c[1],
                                          options: Array(c[2...5]),
                                          answerIndex: answer))
        }
        return questions
    }

    /// Chấm bài: `answers` theo thứ tự câu hỏi, nil = chưa trả lời.
    public static func grade(_ questions: [QuizQuestion],
                             answers: [Int?]) -> QuizGrade {
        var correct = 0
        for (i, question) in questions.enumerated()
        where i < answers.count && answers[i] == question.answerIndex {
            correct += 1
        }
        return QuizGrade(correct: correct, total: questions.count)
    }
}
