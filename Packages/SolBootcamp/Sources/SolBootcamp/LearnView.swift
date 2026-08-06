import SwiftUI
import SolStore
import SolDesignSystem

/// Bootcamp Learn — giáo trình 12 tuần dưới dạng LMS: học theo module, đánh
/// dấu tiến độ từng bài, làm quiz chấm ngay trong app. Trình bày trong sheet
/// từ màn S1. Chỉ dùng token SolColor/SolFont/Sol.* (APP-BR-05).
public struct LearnView: View {
    @State private var model: LearnViewModel
    /// App layer composes navigation (plan §2.3) — "Mở trong Editor" hands
    /// the module Document up, same pattern as WorkspaceView.onOpen.
    private let onOpenDocument: (Document) -> Void

    public init(store: DocumentStore, actor: String = "iPad",
                onOpenDocument: @escaping (Document) -> Void = { _ in }) {
        _model = State(initialValue: LearnViewModel(store: store, actor: actor))
        self.onOpenDocument = onOpenDocument
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                if model.sections.isEmpty {
                    emptyState
                } else {
                    lessonList
                }
            }
            .background(SolColor.bg)
            .navigationDestination(for: Lesson.self) { lesson in
                LessonDetailView(model: model, lessonID: lesson.id,
                                 onOpenDocument: onOpenDocument)
            }
            .overlay(alignment: .bottom) {
                if let error = model.errorMessage {
                    SolToast(error).padding(.bottom, Sol.Spacing.l)
                }
            }
        }
    }

    // MARK: - Header (tiến độ khóa học + tiếp tục học)

    private var header: some View {
        VStack(alignment: .leading, spacing: Sol.Spacing.s) {
            HStack(spacing: Sol.Spacing.s) {
                Text("Bootcamp Learn")
                    .font(SolFont.h1()).foregroundStyle(SolColor.textPrimary)
                Spacer()
                Text("\(model.doneLessons)/\(model.totalLessons) bài · \(model.doneMinutes)/\(model.totalMinutes) phút")
                    .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
            }
            ProgressView(value: model.progress)
                .tint(SolColor.accent)
                .accessibilityLabel("Tiến độ khóa học")
                .accessibilityValue("\(model.doneLessons) trên \(model.totalLessons) bài đã xong")
            if let next = model.continueLesson {
                NavigationLink(value: next) {
                    Label("Tiếp tục: \(next.id) · \(next.title)", systemImage: "play.fill")
                        .lineLimit(1)
                }
                .buttonStyle(SolPrimaryButtonStyle())
                .accessibilityLabel("Tiếp tục học \(next.title)")
            } else if model.totalLessons > 0 {
                Label("Bạn đã hoàn thành toàn bộ giáo trình", systemImage: "checkmark.seal.fill")
                    .font(SolFont.subheading()).foregroundStyle(SolColor.positive)
            }
        }
        .padding(.horizontal, Sol.Spacing.l)
        .padding(.vertical, Sol.Spacing.m)
        .background(SolColor.surface)
    }

    private var emptyState: some View {
        VStack(spacing: Sol.Spacing.m) {
            Text("Không tìm thấy Curriculum")
                .font(SolFont.h2()).foregroundStyle(SolColor.textPrimary)
            Text("Learn cần tài liệu có dòng đầu “\(CurriculumDocument.marker)”. Khôi phục từ Thùng rác nếu bạn đã xóa.")
                .font(SolFont.body()).foregroundStyle(SolColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Sol.Spacing.xl)
    }

    // MARK: - Danh sách bài học theo module

    private var lessonList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Sol.Spacing.m,
                       pinnedViews: .sectionHeaders) {
                ForEach(model.sections) { section in
                    Section {
                        ForEach(section.lessons) { lesson in
                            NavigationLink(value: lesson) {
                                LessonRow(lesson: lesson)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        moduleHeader(section)
                    }
                }
            }
            .padding(.horizontal, Sol.Spacing.l)
            .padding(.bottom, Sol.Spacing.xl)
        }
    }

    private func moduleHeader(_ section: LearnViewModel.ModuleSection) -> some View {
        let done = section.lessons.filter { $0.status == .done }.count
        return HStack(spacing: Sol.Spacing.s) {
            Text(section.name)
                .font(SolFont.h2()).foregroundStyle(SolColor.textPrimary)
            Spacer()
            Text("\(done)/\(section.lessons.count)")
                .font(SolFont.data()).foregroundStyle(
                    done == section.lessons.count ? SolColor.positive : SolColor.textSecondary)
        }
        .padding(.vertical, Sol.Spacing.s)
        .background(SolColor.bg)
    }
}

/// Một dòng bài học: định danh + ngữ cảnh bên trái, trạng thái bên phải.
/// Trạng thái đổi trong màn chi tiết (mở bài ra học rồi mới đánh dấu).
struct LessonRow: View {
    let lesson: Lesson

    var body: some View {
        HStack(spacing: Sol.Spacing.m) {
            Image(systemName: typeIcon)
                .foregroundStyle(lesson.status == .done ? SolColor.positive : SolColor.accent)
                .frame(width: Sol.Chrome.avatar)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Sol.Spacing.xxs) {
                HStack(spacing: Sol.Spacing.s) {
                    Text(lesson.id)
                        .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                    Text(lesson.title)
                        .font(SolFont.body()).foregroundStyle(SolColor.textPrimary)
                        .lineLimit(2)
                }
                Text("\(lesson.week) · \(lesson.type) · \(lesson.durationMinutes) phút\(lesson.score == "—" ? "" : " · Điểm \(lesson.score)")")
                    .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Sol.Spacing.s)
            Text(lesson.status.label)
                .font(SolFont.label())
                .foregroundStyle(statusColor)
                .padding(.horizontal, Sol.Spacing.m)
                .padding(.vertical, Sol.Spacing.xs)
                .background(statusColor.opacity(0.14))
                .clipShape(Capsule())
                .accessibilityLabel("Trạng thái \(lesson.id)")
                .accessibilityValue(lesson.status.label)
            Image(systemName: "chevron.right")
                .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(Sol.Spacing.m)
        .background(SolColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: Sol.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Sol.Radius.card)
            .stroke(SolColor.border, lineWidth: 1))
    }

    private var typeIcon: String {
        switch lesson.type {
        case "Video": "play.rectangle"
        case "Reading": "book"
        case "Exercise": "pencil.and.list.clipboard"
        case "Quiz": "questionmark.circle"
        default: "doc.text"
        }
    }

    /// Màu trạng thái từ semantic tokens (không hard-code — APP-BR-05).
    private var statusColor: Color {
        switch lesson.status {
        case .notStarted: SolColor.textSecondary
        case .inProgress: SolColor.accent
        case .done: SolColor.positive
        }
    }
}

/// Màn chi tiết bài học: nội dung Why/What/How/Action từ tài liệu module,
/// nút đánh dấu tiến độ; dòng Quiz hiện giao diện làm bài thay cho nội dung.
/// Tra bài theo ID để luôn đọc bản sống sau mỗi lần ghi.
struct LessonDetailView: View {
    let model: LearnViewModel
    let lessonID: String
    let onOpenDocument: (Document) -> Void

    var body: some View {
        if let lesson = model.lesson(id: lessonID) {
            ScrollView {
                VStack(alignment: .leading, spacing: Sol.Spacing.l) {
                    lessonHeader(lesson)
                    if lesson.isQuiz {
                        QuizSectionView(model: model, lessonID: lesson.id)
                    } else {
                        if let body = model.lessonBody(for: lesson) {
                            LessonBodyView(markdown: body)
                        }
                        actionBar(lesson)
                    }
                }
                .padding(Sol.Spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(SolColor.bg)
        } else {
            Text("Bài học không còn trong Curriculum.")
                .font(SolFont.body()).foregroundStyle(SolColor.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SolColor.bg)
        }
    }

    private func lessonHeader(_ lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: Sol.Spacing.xs) {
            Text("\(lesson.id) · \(lesson.week)")
                .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
            Text(lesson.title)
                .font(SolFont.h1()).foregroundStyle(SolColor.textPrimary)
            Text("\(lesson.module) · \(lesson.type) · \(lesson.durationMinutes) phút")
                .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
            Text(lesson.objective)
                .font(SolFont.subheading()).foregroundStyle(SolColor.textPrimary)
                .padding(.top, Sol.Spacing.xs)
        }
    }

    private func actionBar(_ lesson: Lesson) -> some View {
        HStack(spacing: Sol.Spacing.m) {
            switch lesson.status {
            case .notStarted:
                Button("Bắt đầu học") { model.setStatus(.inProgress, for: lesson.id) }
                    .buttonStyle(SolPrimaryButtonStyle())
            case .inProgress:
                Button("Đánh dấu Xong") { model.setStatus(.done, for: lesson.id) }
                    .buttonStyle(SolPrimaryButtonStyle())
            case .done:
                Button("Học lại") { model.setStatus(.inProgress, for: lesson.id) }
                    .font(SolFont.subheading()).foregroundStyle(SolColor.accent)
            }
            if let doc = model.moduleDocument(for: lesson) {
                Button("Mở trong Editor") { onOpenDocument(doc) }
                    .font(SolFont.subheading()).foregroundStyle(SolColor.accent)
                    .accessibilityHint("Mở tài liệu module chứa bài học này")
            }
            Spacer()
        }
        .padding(.top, Sol.Spacing.s)
    }
}

/// Trình bày lát markdown của một bài học — bản rút gọn cho màn học (heading
/// phụ, bullet, checkbox, inline bold); bản đầy đủ luôn có qua "Mở trong
/// Editor" (pipeline M2 thật).
struct LessonBodyView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: Sol.Spacing.s) {
            ForEach(Array(markdown.components(separatedBy: "\n").enumerated()),
                    id: \.offset) { _, line in
                render(line.trimmingCharacters(in: .whitespaces))
            }
        }
    }

    @ViewBuilder
    private func render(_ line: String) -> some View {
        if line.isEmpty || line.hasPrefix("## ") {
            // Dòng trống và heading section (đã hiện ở header) — bỏ qua.
            EmptyView()
        } else if line.hasPrefix("### ") {
            Text(String(line.dropFirst(4)))
                .font(SolFont.subheading()).foregroundStyle(SolColor.accentStrong)
                .padding(.top, Sol.Spacing.s)
        } else if line.hasPrefix("- [ ] ") {
            HStack(alignment: .top, spacing: Sol.Spacing.s) {
                Image(systemName: "square")
                    .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                    .padding(.top, Sol.Spacing.xxs)
                inline(String(line.dropFirst(6)))
            }
        } else if line.hasPrefix("- ") {
            HStack(alignment: .top, spacing: Sol.Spacing.s) {
                Text("•").font(SolFont.body()).foregroundStyle(SolColor.textSecondary)
                inline(String(line.dropFirst(2)))
            }
        } else {
            inline(line)
        }
    }

    private func inline(_ text: String) -> some View {
        Text((try? AttributedString(markdown: text)) ?? AttributedString(text))
            .font(SolFont.body()).foregroundStyle(SolColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Giao diện làm quiz: chọn đáp án từng câu, nộp bài để chấm và ghi điểm
/// vào Curriculum. Đạt từ 70% thì dòng quiz tính là Xong; chưa đạt giữ
/// Đang học để làm lại.
struct QuizSectionView: View {
    let model: LearnViewModel
    let lessonID: String

    @State private var questions: [QuizQuestion] = []
    @State private var answers: [Int?] = []
    @State private var grade: QuizGrade?

    var body: some View {
        VStack(alignment: .leading, spacing: Sol.Spacing.l) {
            if let lesson = model.lesson(id: lessonID), lesson.score != "—" {
                Text("Lần nộp gần nhất: \(lesson.score)")
                    .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
            }
            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                questionCard(index: index, question: question)
            }
            resultAndSubmit
        }
        .onAppear {
            guard questions.isEmpty, let lesson = model.lesson(id: lessonID) else { return }
            questions = model.quizQuestions(for: lesson)
            answers = Array(repeating: nil, count: questions.count)
        }
    }

    private func questionCard(index: Int, question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: Sol.Spacing.s) {
            Text("Câu \(question.number). \(question.prompt)")
                .font(SolFont.subheading()).foregroundStyle(SolColor.textPrimary)
            ForEach(Array(question.options.enumerated()), id: \.offset) { optionIndex, option in
                Button {
                    guard grade == nil else { return }
                    answers[index] = optionIndex
                } label: {
                    HStack(alignment: .top, spacing: Sol.Spacing.s) {
                        Image(systemName: answers[index] == optionIndex
                              ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(answers[index] == optionIndex
                                             ? SolColor.accent : SolColor.textSecondary)
                        Text(option)
                            .font(SolFont.body()).foregroundStyle(SolColor.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(Sol.Spacing.s)
                    .background(answers[index] == optionIndex
                                ? SolColor.accent.opacity(0.10) : SolColor.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: Sol.Radius.control))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Câu \(question.number), phương án \(QuizTable.answerLetters[optionIndex])")
                .accessibilityAddTraits(answers[index] == optionIndex ? .isSelected : [])
            }
        }
        .padding(Sol.Spacing.m)
        .background(SolColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: Sol.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Sol.Radius.card)
            .stroke(SolColor.border, lineWidth: 1))
    }

    @ViewBuilder
    private var resultAndSubmit: some View {
        if let grade {
            VStack(alignment: .leading, spacing: Sol.Spacing.s) {
                Label(grade.passed
                      ? "Đạt \(grade.correct)/\(grade.total) — quiz tính là Xong."
                      : "\(grade.correct)/\(grade.total) — cần từ 70% để đạt. Ôn lại bài rồi làm lại nhé.",
                      systemImage: grade.passed ? "checkmark.seal.fill" : "arrow.counterclockwise")
                    .font(SolFont.subheading())
                    .foregroundStyle(grade.passed ? SolColor.positive : SolColor.danger)
                Button("Làm lại") {
                    self.grade = nil
                    answers = Array(repeating: nil, count: questions.count)
                }
                .font(SolFont.subheading()).foregroundStyle(SolColor.accent)
            }
        } else {
            Button("Nộp bài") {
                guard let lesson = model.lesson(id: lessonID) else { return }
                grade = model.submitQuiz(answers: answers, for: lesson)
            }
            .buttonStyle(SolPrimaryButtonStyle())
            .disabled(answers.contains(nil) || questions.isEmpty)
            .accessibilityHint("Chấm điểm và ghi kết quả vào Curriculum")
        }
    }
}
