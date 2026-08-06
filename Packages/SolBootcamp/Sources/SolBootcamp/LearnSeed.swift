import Foundation
import SolStore

/// Seed "Bootcamp Learn" — giáo trình 12 tuần của BA Bootcamp dưới dạng LMS:
/// 1 tài liệu Curriculum (bảng bài học + Status/Score) và 5 tài liệu Module
/// (nội dung bài học theo template Why/What/How/Action của CM-01, kèm quiz).
///
/// Tất cả là `.md` + `sol-data` thường — render qua pipeline M2/M3 như mọi
/// tài liệu khác; Learn chỉ thêm giao diện học + quiz lên trên. Tách marker
/// khỏi BootcampSeed để workspace đã seed Bootcamp OS (trước bản này) vẫn
/// nhận được giáo trình ở lần mở kế tiếp.
public enum LearnSeed {
    /// Marker ẩn trong workspace root — DocumentStore chỉ list `*.md` nên
    /// không bao giờ hiện thành tài liệu. Có mặt = "đã seed": người dùng đã
    /// xóa tài liệu giáo trình thì KHÔNG được hồi sinh (user intent wins,
    /// cùng tinh thần BootcampSeed).
    public static let markerName = ".sol-seed-learn-v1"

    /// Cài bộ giáo trình một lần cho mỗi workspace. Trả về true khi chính
    /// lời gọi này cài tài liệu.
    @discardableResult
    public static func installIfNeeded(into store: DocumentStore) throws -> Bool {
        let marker = store.root.appendingPathComponent(markerName)
        guard !FileManager.default.fileExists(atPath: marker.path) else { return false }
        for doc in documents {
            try store.createDocument(named: doc.name, contents: doc.body)
        }
        try Data().write(to: marker)
        return true
    }

    /// Tiền tố "BA Bootcamp — 1x" xếp bộ Learn ngay sau bộ Bootcamp OS
    /// (00–03) trong workspace phẳng M1.
    public static let documents: [(name: String, body: String)] = [
        (name: "BA Bootcamp — 10 · Curriculum", body: curriculum),
        (name: "BA Bootcamp — 11 · Module 1", body: module1),
        (name: "BA Bootcamp — 12 · Module 2", body: module2),
        (name: "BA Bootcamp — 13 · Module 3", body: module3),
        (name: "BA Bootcamp — 14 · Module 4", body: module4),
        (name: "BA Bootcamp — 15 · Module 5", body: module5),
    ]

    // MARK: - 10 · Curriculum (29 mục — 24 bài học + 5 quiz · 970 phút)

    static let curriculum = """
    # BA Bootcamp — Curriculum

    Giáo trình 12 tuần · 5 module · 29 mục (24 bài học + 5 quiz) · 970 phút.

    Học ngay trong app: mở **Bootcamp Learn** từ màn Workspace, chạm vào bài
    để đọc nội dung và đánh dấu tiến độ; dòng **Quiz** mở bài trắc nghiệm
    chấm ngay trong app (đạt từ 70% thì tính là Xong). Status và Score ghi
    thẳng vào bảng dưới đây — tài liệu này là nguồn sự thật, sửa ở Editor
    hay ở Learn đều thấy nhau.

    ## Module 1 · Foundations & Business Thinking (Wk 1–2)

    | ID | Week | Lesson | Objective | Type | Duration (min) | Status | Score |
    | --- | --- | --- | --- | --- | --- | --- | --- |
    | L1-01 | Wk 1 | Nghề BA trong tổ chức | Định vị vai trò BA giữa business và delivery | Reading | 25 | Not started | — |
    | L1-02 | Wk 1 | Tư duy kinh doanh & value chain | Nhìn doanh nghiệp theo dòng giá trị để đặt vấn đề đúng chỗ | Video | 30 | Not started | — |
    | L1-03 | Wk 2 | Stakeholder map & RACI | Lập bản đồ stakeholder và phân định trách nhiệm | Exercise | 40 | Not started | — |
    | L1-04 | Wk 2 | Positioning một trang | Chốt vấn đề, mục tiêu, phạm vi trên một trang giấy | Exercise | 35 | Not started | — |
    | L1-05 | Wk 2 | Quiz Module 1 | Kiểm tra kiến thức nền tảng | Quiz | 15 | Not started | — |

    ## Module 2 · Discovery & Requirements (Wk 3–5)

    | ID | Week | Lesson | Objective | Type | Duration (min) | Status | Score |
    | --- | --- | --- | --- | --- | --- | --- | --- |
    | L2-01 | Wk 3 | Lập kế hoạch elicitation | Chọn đúng người, đúng kỹ thuật cho từng loại thông tin | Reading | 30 | Not started | — |
    | L2-02 | Wk 3 | Kỹ thuật phỏng vấn stakeholder | Dẫn phỏng vấn bằng câu hỏi mở và five-whys | Video | 35 | Not started | — |
    | L2-03 | Wk 4 | Viết BRD | Cấu trúc một Business Requirements Document kiểm chứng được | Exercise | 45 | Not started | — |
    | L2-04 | Wk 4 | User story & acceptance criteria | Viết story đúng định dạng kèm tiêu chí nghiệm thu | Video | 30 | Not started | — |
    | L2-05 | Wk 5 | Ưu tiên backlog với MoSCoW | Xếp Must/Should/Could và bảo vệ được lựa chọn | Exercise | 30 | Not started | — |
    | L2-06 | Wk 5 | Traceability matrix | Nối yêu cầu với mục tiêu và test để không rơi rớt | Reading | 25 | Not started | — |
    | L2-07 | Wk 5 | Quiz Module 2 | Kiểm tra kiến thức discovery & requirements | Quiz | 15 | Not started | — |

    ## Module 3 · Analysis & Solution Design (Wk 6–8)

    | ID | Week | Lesson | Objective | Type | Duration (min) | Status | Score |
    | --- | --- | --- | --- | --- | --- | --- | --- |
    | L3-01 | Wk 6 | Mô hình hóa quy trình với BPMN | Vẽ quy trình as-is bằng ký hiệu BPMN cốt lõi | Video | 40 | Not started | — |
    | L3-02 | Wk 6 | Swimlane & phân tích as-is/to-be | Tìm điểm nghẽn và thiết kế quy trình to-be | Exercise | 40 | Not started | — |
    | L3-03 | Wk 7 | Wireframe & functional spec | Phác màn hình và viết spec chức năng từ user story | Exercise | 45 | Not started | — |
    | L3-04 | Wk 7 | SQL cơ bản cho BA | Dùng SELECT, WHERE, ORDER BY trên dữ liệu thật | Video | 45 | Not started | — |
    | L3-05 | Wk 8 | SQL join & tổng hợp dữ liệu | Dùng JOIN và GROUP BY để trả lời câu hỏi business | Exercise | 45 | Not started | — |
    | L3-06 | Wk 8 | Data dictionary | Định nghĩa trường dữ liệu để cả team nói cùng một ngôn ngữ | Reading | 25 | Not started | — |
    | L3-07 | Wk 8 | Quiz Module 3 | Kiểm tra kiến thức analysis & solution design | Quiz | 15 | Not started | — |

    ## Module 4 · Implementation, Data & Validation (Wk 9–10)

    | ID | Week | Lesson | Objective | Type | Duration (min) | Status | Score |
    | --- | --- | --- | --- | --- | --- | --- | --- |
    | L4-01 | Wk 9 | BA trong Agile/Scrum | Vai trò BA trong sprint: refine, clarify, verify | Video | 30 | Not started | — |
    | L4-02 | Wk 9 | UAT plan & test case | Lập kế hoạch UAT và viết test case từ acceptance criteria | Exercise | 40 | Not started | — |
    | L4-03 | Wk 10 | Kịch bản Gherkin | Viết Given-When-Then cho các luồng chính | Exercise | 35 | Not started | — |
    | L4-04 | Wk 10 | Đo lường sau go-live | Chọn chỉ số outcome và vòng phản hồi sau triển khai | Reading | 25 | Not started | — |
    | L4-05 | Wk 10 | Quiz Module 4 | Kiểm tra kiến thức implementation & validation | Quiz | 15 | Not started | — |

    ## Module 5 · Capstone & Career Launch (Wk 11–12)

    | ID | Week | Lesson | Objective | Type | Duration (min) | Status | Score |
    | --- | --- | --- | --- | --- | --- | --- | --- |
    | L5-01 | Wk 11 | Capstone: phân tích đề bài | Đọc case, xác định stakeholder và vấn đề gốc | Exercise | 60 | Not started | — |
    | L5-02 | Wk 11 | Capstone: thiết kế giải pháp | Dựng quy trình to-be, yêu cầu và wireframe cho case | Exercise | 60 | Not started | — |
    | L5-03 | Wk 12 | Capstone: trình bày & phản biện | Kể câu chuyện giải pháp trong 10 phút thuyết phục | Exercise | 45 | Not started | — |
    | L5-04 | Wk 12 | CV, portfolio & phỏng vấn BA | Đóng gói artefact thành portfolio và luyện trả lời STAR | Video | 35 | Not started | — |
    | L5-05 | Wk 12 | Quiz Module 5 | Kiểm tra kiến thức capstone & career | Quiz | 15 | Not started | — |

    ## Thời lượng theo module

    ```sol-data type=bar title="Thời lượng học (phút) theo module"
    module,minutes
    Module 1,145
    Module 2,210
    Module 3,255
    Module 4,145
    Module 5,215
    ```
    """

    // MARK: - 11 · Module 1

    static let module1 = """
    # BA Bootcamp — Module 1 · Foundations & Business Thinking

    Tuần 1–2 · 4 bài học + 1 quiz · 145 phút. Học xong module này bạn định vị
    được vai trò BA, đọc được doanh nghiệp theo dòng giá trị, và có bộ công
    cụ stakeholder trước khi bước vào requirements.

    ## L1-01 · Nghề BA trong tổ chức

    **Mục tiêu:** Định vị vai trò BA giữa business và delivery.

    ### Why
    Phần lớn dự án thất bại vì xây đúng thứ sai. BA tồn tại để giữ cho tổ
    chức xây đúng thứ đáng xây — trước khi bàn xây thế nào.

    ### What
    - BA là cầu nối business và delivery: dịch vấn đề thành yêu cầu kiểm chứng được.
    - Ranh giới và vùng chồng lấn với PM, PO, Data Analyst.
    - Ba đầu ra cốt lõi: vấn đề được hiểu đúng, yêu cầu rõ ràng, giải pháp được nghiệm thu.

    ### How
    Đọc bài, sau đó đối chiếu với tổ chức bạn đang làm: ai đang làm việc của
    BA, và khoảng trống nằm ở đâu?

    ### Action
    - [ ] Viết 5 dòng mô tả một vấn đề business ở nơi bạn làm việc theo góc nhìn BA (vấn đề, ai bị ảnh hưởng, chi phí của việc không làm gì).

    ## L1-02 · Tư duy kinh doanh & value chain

    **Mục tiêu:** Nhìn doanh nghiệp theo dòng giá trị để đặt vấn đề đúng chỗ.

    ### Why
    Yêu cầu chỉ có nghĩa khi gắn vào cách doanh nghiệp tạo ra tiền — value
    chain cho bạn tấm bản đồ đó.

    ### What
    - Value chain: hoạt động chính và hoạt động hỗ trợ, giá trị chảy về khách hàng thế nào.
    - Revenue model và cost driver — câu hỏi "tính năng này chạm vào dòng nào?".
    - Nối một yêu cầu bất kỳ ngược về mục tiêu kinh doanh đo được.

    ### How
    Xem video, tạm dừng ở mỗi ví dụ và tự vẽ lại value chain của một doanh
    nghiệp bạn biết rõ.

    ### Action
    - [ ] Vẽ value chain một trang cho công ty bạn chọn và đánh dấu nơi vấn đề ở L1-01 đang nằm.

    ## L1-03 · Stakeholder map & RACI

    **Mục tiêu:** Lập bản đồ stakeholder và phân định trách nhiệm.

    ### Why
    Dự án không đổ vì thiếu template — đổ vì sót người có quyền phủ quyết
    hoặc hỏi sai người ngay từ đầu.

    ### What
    - Lưới ảnh hưởng/quan tâm: ai cần giữ hài lòng, ai cần cập nhật đúng mức, ai cần đồng hành sát.
    - RACI: Responsible, Accountable, Consulted, Informed — mỗi việc đúng một A.
    - Tín hiệu stakeholder ẩn: người ký ngân sách, người vận hành hằng ngày, người nói "không".

    ### How
    Làm bài tập với template Stakeholder map và RACI trong bộ Foundations
    templates (CM-14).

    ### Action
    - [ ] Lập stakeholder map và bảng RACI cho vấn đề bạn theo đuổi từ L1-01.

    ## L1-04 · Positioning một trang

    **Mục tiêu:** Chốt vấn đề, mục tiêu, phạm vi trên một trang giấy.

    ### Why
    Nếu không viết gọn được vấn đề trong một trang, mọi cuộc họp sau đó sẽ
    trả giá bằng thời gian của cả team.

    ### What
    - Cấu trúc positioning one-pager: bối cảnh, vấn đề, mục tiêu đo được, phạm vi trong/ngoài, rủi ro.
    - Mục tiêu tốt là mục tiêu đo được: con số, mốc thời gian, người chịu trách nhiệm.
    - Phạm vi "ngoài" quan trọng ngang phạm vi "trong".

    ### How
    Điền template positioning one-pager cho case của bạn, sau đó tự phản
    biện: dòng nào chưa kiểm chứng được thì viết lại.

    ### Action
    - [ ] Hoàn thành positioning one-pager và gửi một đồng nghiệp đọc thử — họ có kể lại đúng vấn đề trong 30 giây không?

    ## L1-05 · Quiz Module 1

    Trả lời 4 câu, đạt từ 70% (3/4) để hoàn thành module. Sai thì ôn lại bài
    tương ứng và làm lại — điểm mới ghi đè điểm cũ.

    | # | Câu hỏi | A | B | C | D | Đáp án |
    | --- | --- | --- | --- | --- | --- | --- |
    | 1 | Vai trò cốt lõi của BA là gì? | Viết code cho tính năng | Cầu nối business và delivery, biến vấn đề thành yêu cầu kiểm chứng được | Quản lý ngân sách dự án | Thiết kế giao diện sản phẩm | B |
    | 2 | RACI dùng để làm gì? | Ước lượng effort | Vẽ quy trình nghiệp vụ | Phân định trách nhiệm trên từng đầu việc | Theo dõi lỗi phần mềm | C |
    | 3 | Nhóm stakeholder "ảnh hưởng cao, quan tâm thấp" nên được xử lý thế nào? | Bỏ qua vì họ không quan tâm | Gửi mọi tài liệu chi tiết | Giữ hài lòng và cập nhật đúng mức | Mời vào mọi cuộc họp hằng ngày | C |
    | 4 | Value chain giúp BA điều gì? | Thấy hoạt động nào tạo giá trị để đặt vấn đề đúng chỗ | Tính lương cho team | Chọn công nghệ triển khai | Viết test case nhanh hơn | A |
    """

    // MARK: - 12 · Module 2

    static let module2 = """
    # BA Bootcamp — Module 2 · Discovery & Requirements

    Tuần 3–5 · 6 bài học + 1 quiz · 210 phút. Học xong module này bạn khai
    thác được thông tin từ stakeholder và biến nó thành yêu cầu có cấu trúc,
    có thứ tự ưu tiên, truy vết được.

    ## L2-01 · Lập kế hoạch elicitation

    **Mục tiêu:** Chọn đúng người, đúng kỹ thuật cho từng loại thông tin.

    ### Why
    Elicitation không có kế hoạch là một chuỗi cuộc họp lan man — tốn giờ của
    stakeholder và lòng tin của bạn.

    ### What
    - Ba câu hỏi của một elicitation plan: cần biết gì, hỏi ai, bằng kỹ thuật nào.
    - Chọn kỹ thuật theo loại thông tin: phỏng vấn, workshop, quan sát, phân tích tài liệu, khảo sát.
    - Chuẩn bị trước mỗi phiên: mục tiêu, câu hỏi mồi, cách ghi nhận.

    ### How
    Đọc bài và điền elicitation plan template (CM-15) cho case của bạn.

    ### Action
    - [ ] Lập elicitation plan cho 3 stakeholder quan trọng nhất trong map ở L1-03.

    ## L2-02 · Kỹ thuật phỏng vấn stakeholder

    **Mục tiêu:** Dẫn phỏng vấn bằng câu hỏi mở và five-whys.

    ### Why
    Stakeholder kể giải pháp họ muốn; việc của BA là lần ngược về vấn đề họ
    thật sự có.

    ### What
    - Câu hỏi mở và câu hỏi đóng — khi nào dùng loại nào.
    - Five-whys: lần từ triệu chứng về nguyên nhân gốc mà không thẩm vấn.
    - Kỹ thuật nghe chủ động: nhắc lại, tóm tắt, xác nhận hiểu đúng.

    ### How
    Xem video demo hai buổi phỏng vấn (một tệ, một tốt) và ghi lại khác biệt.

    ### Action
    - [ ] Thực hiện một buổi phỏng vấn 30 phút theo interview guide và ghi lại 3 insight bất ngờ nhất.

    ## L2-03 · Viết BRD

    **Mục tiêu:** Cấu trúc một Business Requirements Document kiểm chứng được.

    ### Why
    BRD là hợp đồng hiểu-đúng giữa business và delivery — mơ hồ ở đây thì trả
    giá gấp mười ở giai đoạn build.

    ### What
    - Khung BRD: bối cảnh, mục tiêu, phạm vi, yêu cầu business, yêu cầu chức năng, ràng buộc.
    - Một yêu cầu tốt: nguyên tử, kiểm chứng được, không mô tả giải pháp khi chưa cần.
    - Mã hóa yêu cầu để truy vết (BR-01, FR-01…).

    ### How
    Viết BRD cho case của bạn bằng template CM-15, tối đa 4 trang.

    ### Action
    - [ ] Hoàn thành BRD v0.1 và đánh dấu những yêu cầu bạn chưa kiểm chứng được nguồn.

    ## L2-04 · User story & acceptance criteria

    **Mục tiêu:** Viết story đúng định dạng kèm tiêu chí nghiệm thu.

    ### Why
    Story không có acceptance criteria là lời hứa không có cách nghiệm thu —
    dev đoán, tester đoán, và hai bên đoán khác nhau.

    ### What
    - Định dạng chuẩn: "As a … I want … so that …" — vai, nhu cầu, giá trị.
    - INVEST: story tốt thì độc lập, thương lượng được, có giá trị, ước lượng được, nhỏ, kiểm thử được.
    - Acceptance criteria cụ thể, quan sát được, không mô tả cách cài đặt.

    ### How
    Xem video, sau đó chẻ 2 yêu cầu trong BRD của bạn thành story kèm criteria.

    ### Action
    - [ ] Viết 5 user story từ BRD ở L2-03, mỗi story có ít nhất 2 acceptance criteria.

    ## L2-05 · Ưu tiên backlog với MoSCoW

    **Mục tiêu:** Xếp Must/Should/Could và bảo vệ được lựa chọn.

    ### Why
    Khi mọi thứ đều "quan trọng" thì không thứ gì được làm tử tế — ưu tiên là
    kỹ năng nói không có căn cứ.

    ### What
    - MoSCoW: Must (thiếu là không phát hành được), Should, Could, Won't-this-time.
    - Căn cứ xếp hạng: giá trị, rủi ro, phụ thuộc, chi phí trì hoãn.
    - Nghệ thuật bảo vệ thứ tự trước stakeholder có tiếng nói lớn.

    ### How
    Xếp backlog story của bạn theo MoSCoW rồi viết một dòng căn cứ cho mỗi Must.

    ### Action
    - [ ] Xếp hạng 5 story ở L2-04 và trình bày căn cứ trong 1 đoạn ngắn cho mỗi Must.

    ## L2-06 · Traceability matrix

    **Mục tiêu:** Nối yêu cầu với mục tiêu và test để không rơi rớt.

    ### Why
    Yêu cầu không truy vết được là yêu cầu sẽ bị quên — hoặc tệ hơn, được xây
    mà không ai nhớ vì sao.

    ### What
    - Ma trận truy vết: mục tiêu ↔ yêu cầu ↔ story ↔ test case.
    - Phát hiện lỗ hổng: yêu cầu mồ côi (không phục vụ mục tiêu nào) và mục tiêu trống (không yêu cầu nào phục vụ).
    - Giữ ma trận sống cùng thay đổi — cập nhật khi backlog đổi.

    ### How
    Đọc bài và điền traceability matrix template cho case của bạn.

    ### Action
    - [ ] Lập ma trận truy vết cho toàn bộ yêu cầu ở L2-03 và tìm ra ít nhất 1 lỗ hổng.

    ## L2-07 · Quiz Module 2

    Trả lời 4 câu, đạt từ 70% (3/4) để hoàn thành module.

    | # | Câu hỏi | A | B | C | D | Đáp án |
    | --- | --- | --- | --- | --- | --- | --- |
    | 1 | Elicitation plan trả lời những câu hỏi nào? | Chi phí, tiến độ, nhân sự | Cần biết gì, hỏi ai, bằng kỹ thuật nào | Công nghệ, kiến trúc, hạ tầng | Doanh thu, lợi nhuận, thị phần | B |
    | 2 | Five-whys dùng để làm gì? | Ước lượng story point | Chốt phạm vi dự án | Lần từ triệu chứng về nguyên nhân gốc | Đánh giá hiệu năng hệ thống | C |
    | 3 | User story đúng định dạng là gì? | As a - I want - so that | Given - When - Then | Input - Process - Output | Plan - Do - Check - Act | A |
    | 4 | Trong MoSCoW, "Must" nghĩa là gì? | Làm nếu còn thời gian | Nên có nhưng cắt được | Thiếu nó thì không thể phát hành | Để dành cho bản sau | C |
    """

    // MARK: - 13 · Module 3

    static let module3 = """
    # BA Bootcamp — Module 3 · Analysis & Solution Design

    Tuần 6–8 · 6 bài học + 1 quiz · 255 phút. Học xong module này bạn mô hình
    hóa được quy trình, phác được giải pháp, và tự truy vấn dữ liệu bằng SQL
    thay vì chờ người khác xuất báo cáo.

    ## L3-01 · Mô hình hóa quy trình với BPMN

    **Mục tiêu:** Vẽ quy trình as-is bằng ký hiệu BPMN cốt lõi.

    ### Why
    Văn xuôi mô tả quy trình luôn có kẽ hở — sơ đồ buộc mọi nhánh rẽ và ngoại
    lệ phải lộ diện.

    ### What
    - Bộ ký hiệu tối thiểu đủ dùng: sự kiện, hoạt động, cổng rẽ nhánh, luồng.
    - Nguyên tắc một trang: quy trình không vừa một trang là chưa hiểu đủ sâu.
    - Bẫy thường gặp: vẽ hệ thống thay vì vẽ nghiệp vụ.

    ### How
    Xem video vẽ mẫu một quy trình duyệt đơn từ đầu đến cuối, rồi vẽ lại theo.

    ### Action
    - [ ] Vẽ BPMN as-is cho quy trình trung tâm trong case của bạn bằng BPMN starter template.

    ## L3-02 · Swimlane & phân tích as-is/to-be

    **Mục tiêu:** Tìm điểm nghẽn và thiết kế quy trình to-be.

    ### Why
    Điểm nghẽn thường nằm ở chỗ bàn giao giữa các vai — swimlane phơi những
    chỗ bàn giao đó ra ánh sáng.

    ### What
    - Swimlane: mỗi làn một vai, mỗi lần luồng vượt làn là một lần bàn giao có rủi ro.
    - Định lượng as-is: thời gian chờ, tỉ lệ lỗi, số vòng lặp lại.
    - Thiết kế to-be: bỏ, gộp, tự động hóa, đổi thứ tự — theo đúng trình tự đó.

    ### How
    Chuyển BPMN ở L3-01 sang swimlane, đo đếm as-is, rồi phác bản to-be.

    ### Action
    - [ ] Hoàn thành cặp sơ đồ as-is/to-be và một bảng so sánh 3 chỉ số trước/sau.

    ## L3-03 · Wireframe & functional spec

    **Mục tiêu:** Phác màn hình và viết spec chức năng từ user story.

    ### Why
    Wireframe rẻ hơn code một nghìn lần — cãi nhau trên giấy luôn rẻ hơn cãi
    nhau trên sản phẩm đã build.

    ### What
    - Wireframe fidelity thấp: bố cục và luồng, không màu mè.
    - Functional spec: hành vi từng thành phần, trạng thái, ngoại lệ, thông điệp lỗi.
    - Nối wireframe với story và acceptance criteria thành một bộ đọc-là-build-được.

    ### How
    Dùng wireframe kit phác 2 màn hình chính cho story Must của bạn, viết spec kèm theo.

    ### Action
    - [ ] Hoàn thành 2 wireframe + functional spec cho story quan trọng nhất ở L2-04.

    ## L3-04 · SQL cơ bản cho BA

    **Mục tiêu:** Dùng SELECT, WHERE, ORDER BY trên dữ liệu thật.

    ### Why
    BA tự truy vấn được dữ liệu thì kiểm chứng giả định trong phút thay vì
    chờ báo cáo trong tuần.

    ### What
    - SELECT và FROM: chọn cột, chọn bảng, đặt alias dễ đọc.
    - WHERE: lọc theo điều kiện, kết hợp AND/OR, cẩn thận với NULL.
    - ORDER BY và LIMIT: sắp xếp và lấy đúng phần cần nhìn.

    ### How
    Xem video thao tác trên SQL sandbox (CM-27) và gõ lại từng truy vấn.

    ### Action
    - [ ] Hoàn thành 10 bài truy vấn cơ bản đầu tiên trong SQL query workbook.

    ## L3-05 · SQL join & tổng hợp dữ liệu

    **Mục tiêu:** Dùng JOIN và GROUP BY để trả lời câu hỏi business.

    ### Why
    Câu hỏi business thật hiếm khi nằm gọn trong một bảng — join và group là
    cách bạn ghép câu trả lời từ nhiều mảnh.

    ### What
    - INNER JOIN và LEFT JOIN: khi nào mất dòng, khi nào giữ dòng không khớp.
    - GROUP BY với COUNT, SUM, AVG — đọc kết quả theo đơn vị phân tích.
    - HAVING: lọc sau khi gộp, khác WHERE thế nào.

    ### How
    Làm bài tập trên sandbox: mỗi bài là một câu hỏi business, không phải một
    câu lệnh.

    ### Action
    - [ ] Trả lời 5 câu hỏi business trong workbook bằng truy vấn có JOIN và GROUP BY.

    ## L3-06 · Data dictionary

    **Mục tiêu:** Định nghĩa trường dữ liệu để cả team nói cùng một ngôn ngữ.

    ### Why
    "Doanh thu" của kế toán khác "doanh thu" của marketing — data dictionary
    là nơi tranh luận đó được chốt một lần.

    ### What
    - Mỗi trường: tên, kiểu, định nghĩa nghiệp vụ, nguồn, quy tắc hợp lệ.
    - Định nghĩa nghiệp vụ viết cho người, không viết cho máy.
    - Ai là chủ định nghĩa — và quy trình khi hai phòng ban định nghĩa vênh nhau.

    ### How
    Đọc bài và điền data dictionary template cho các bảng trong SQL sandbox.

    ### Action
    - [ ] Lập data dictionary cho 2 bảng bạn dùng nhiều nhất ở L3-05.

    ## L3-07 · Quiz Module 3

    Trả lời 4 câu, đạt từ 70% (3/4) để hoàn thành module.

    | # | Câu hỏi | A | B | C | D | Đáp án |
    | --- | --- | --- | --- | --- | --- | --- |
    | 1 | Swimlane trong sơ đồ quy trình thể hiện điều gì? | Thời gian mỗi bước | Vai nào chịu trách nhiệm bước nào | Chi phí từng bước | Hệ thống nào lưu dữ liệu | B |
    | 2 | Phân tích as-is/to-be nghĩa là gì? | So sánh chi phí hai nhà cung cấp | So sánh quy trình hiện tại với quy trình thiết kế mới | So sánh hai bản wireframe | So sánh kế hoạch với thực tế chi tiêu | B |
    | 3 | Lệnh SQL nào dùng để lấy dữ liệu từ bảng? | INSERT | UPDATE | SELECT | DELETE | C |
    | 4 | LEFT JOIN khác INNER JOIN thế nào? | Chạy nhanh hơn | Giữ mọi dòng của bảng bên trái kể cả khi không khớp | Chỉ dùng được cho hai bảng | Tự động gộp dòng trùng | B |
    """

    // MARK: - 14 · Module 4

    static let module4 = """
    # BA Bootcamp — Module 4 · Implementation, Data & Validation

    Tuần 9–10 · 4 bài học + 1 quiz · 145 phút. Học xong module này bạn đồng
    hành được với team Agile trong lúc build, nghiệm thu bằng UAT có kịch
    bản, và đo được kết quả sau go-live.

    ## L4-01 · BA trong Agile/Scrum

    **Mục tiêu:** Vai trò BA trong sprint: refine, clarify, verify.

    ### Why
    Yêu cầu tốt đến đâu cũng chết nếu không ai chăm nó trong sprint — BA là
    người giữ cho ngữ cảnh không thất lạc giữa các buổi họp.

    ### What
    - Nhịp Scrum và chỗ đứng của BA: refinement, planning, review.
    - Refine backlog cùng PO: chẻ nhỏ, làm rõ, bổ sung acceptance criteria trước khi vào sprint.
    - Trả lời câu hỏi của dev/tester trong ngày — chi phí của câu trả lời chậm.

    ### How
    Xem video một sprint thu nhỏ qua góc nhìn BA, ghi lại các điểm chạm.

    ### Action
    - [ ] Viết checklist "definition of ready" cho story trước khi vào sprint, áp lên 5 story của bạn.

    ## L4-02 · UAT plan & test case

    **Mục tiêu:** Lập kế hoạch UAT và viết test case từ acceptance criteria.

    ### Why
    UAT không phải để tìm bug kỹ thuật — để xác nhận nghiệp vụ chạy được bằng
    tay người dùng thật, trước khi ký nghiệm thu.

    ### What
    - UAT plan: phạm vi, người test, dữ liệu, môi trường, tiêu chí đạt.
    - Từ acceptance criteria sang test case: bước làm, dữ liệu vào, kết quả mong đợi.
    - Phân loại kết quả: đạt, lỗi chặn, lỗi ghi nhận sửa sau.

    ### How
    Dùng UAT plan và test-case sheet (CM-17) cho story Must của bạn.

    ### Action
    - [ ] Viết UAT plan và 10 test case cho 2 story quan trọng nhất.

    ## L4-03 · Kịch bản Gherkin

    **Mục tiêu:** Viết Given-When-Then cho các luồng chính.

    ### Why
    Gherkin là ngôn ngữ chung hiếm hoi mà business đọc hiểu và máy chạy được
    — một kịch bản, hai khán giả.

    ### What
    - Cấu trúc Given-When-Then: bối cảnh, hành động, kết quả quan sát được.
    - Scenario outline: một kịch bản chạy nhiều bộ dữ liệu.
    - Bẫy thường gặp: nhét chi tiết giao diện vào kịch bản nghiệp vụ.

    ### How
    Chuyển 5 test case ở L4-02 thành kịch bản Gherkin bằng cheat-sheet.

    ### Action
    - [ ] Viết 5 kịch bản Gherkin phủ luồng chính và ít nhất 1 ngoại lệ.

    ## L4-04 · Đo lường sau go-live

    **Mục tiêu:** Chọn chỉ số outcome và vòng phản hồi sau triển khai.

    ### Why
    Phát hành xong chưa phải là xong — tính năng không ai dùng là thất bại
    được ngụy trang bằng lễ go-live.

    ### What
    - Output và outcome: đã ship khác với đã tạo giá trị.
    - Chọn 3–5 chỉ số gắn với mục tiêu ở positioning one-pager (L1-04).
    - Vòng phản hồi: đo, học, đề xuất vòng cải tiến kế tiếp.

    ### How
    Đọc bài và soạn bảng chỉ số cho case của bạn: chỉ số, nguồn dữ liệu, tần
    suất đo, ngưỡng hành động.

    ### Action
    - [ ] Lập bảng đo lường sau go-live với 3 chỉ số outcome cho case của bạn.

    ## L4-05 · Quiz Module 4

    Trả lời 4 câu, đạt từ 70% (3/4) để hoàn thành module.

    | # | Câu hỏi | A | B | C | D | Đáp án |
    | --- | --- | --- | --- | --- | --- | --- |
    | 1 | Trong Scrum, đóng góp thường trực của BA là gì? | Viết code thay dev khi gấp | Refine backlog và làm rõ yêu cầu cùng PO | Quản lý ngân sách sprint | Quyết định kiến trúc hệ thống | B |
    | 2 | Mục đích chính của UAT là gì? | Tìm lỗi bảo mật | Đo hiệu năng hệ thống | Người dùng xác nhận nghiệp vụ chạy đúng trước nghiệm thu | Kiểm tra tương thích trình duyệt | C |
    | 3 | Cấu trúc của một kịch bản Gherkin là gì? | Input - Output | Given - When - Then | Arrange - Act - Assert | Why - What - How | B |
    | 4 | Sau go-live, chỉ số nào đáng đo nhất? | Số dòng code đã viết | Số cuộc họp đã tổ chức | Chỉ số outcome gắn với mục tiêu business | Số tài liệu đã tạo | C |
    """

    // MARK: - 15 · Module 5

    static let module5 = """
    # BA Bootcamp — Module 5 · Capstone & Career Launch

    Tuần 11–12 · 4 bài học + 1 quiz · 215 phút. Module cuối: làm capstone
    trên case thực tế từ đầu đến cuối, rồi đóng gói thành portfolio và chuẩn
    bị bước vào thị trường với vai trò BA.

    ## L5-01 · Capstone: phân tích đề bài

    **Mục tiêu:** Đọc case, xác định stakeholder và vấn đề gốc.

    ### Why
    Capstone chấm cách bạn nghĩ trước khi chấm thứ bạn vẽ — lao vào giải pháp
    khi chưa phân tích là lỗi nặng nhất của rubric.

    ### What
    - Đọc capstone brief và dataset kèm theo (CM-26): bối cảnh, ràng buộc, dữ liệu.
    - Áp bộ công cụ Module 1: stakeholder map, five-whys về vấn đề gốc, positioning one-pager.
    - Kiểm chứng giả định bằng dữ liệu của case — đừng tin lời kể một chiều trong brief.

    ### How
    Làm việc như một engagement thật: đọc brief hai lần, đặt câu hỏi trước
    khi kết luận, ghi lại giả định chưa kiểm chứng.

    ### Action
    - [ ] Nộp positioning one-pager + stakeholder map cho case capstone.

    ## L5-02 · Capstone: thiết kế giải pháp

    **Mục tiêu:** Dựng quy trình to-be, yêu cầu và wireframe cho case.

    ### Why
    Đây là nơi mọi kỹ năng của 10 tuần hợp lại thành một bộ artefact — thứ sẽ
    trở thành trang đinh trong portfolio của bạn.

    ### What
    - Quy trình to-be với swimlane, đối chiếu as-is từ dữ liệu case.
    - Backlog yêu cầu xếp MoSCoW + traceability về mục tiêu.
    - Wireframe và functional spec cho luồng quan trọng nhất.

    ### How
    Theo đúng trình tự đã học: quy trình trước, yêu cầu sau, màn hình cuối.
    Đối chiếu rubric (CM-28) trước khi nộp.

    ### Action
    - [ ] Nộp bộ giải pháp: sơ đồ to-be, backlog MoSCoW, 2 wireframe + spec.

    ## L5-03 · Capstone: trình bày & phản biện

    **Mục tiêu:** Kể câu chuyện giải pháp trong 10 phút thuyết phục.

    ### Why
    Phân tích hay mà kể không ra chuyện thì stakeholder không gật — trình bày
    là kỹ năng ra quyết định, không phải kỹ năng trang trí slide.

    ### What
    - Cấu trúc 10 phút: vấn đề, chi phí của hiện trạng, giải pháp, bằng chứng, đề nghị.
    - Trả lời phản biện: nhận câu hỏi khó mà không phòng thủ.
    - Một slide một ý — bảng số liệu dày để ở phụ lục.

    ### How
    Dựng deck từ artefact ở L5-02, tập nói có bấm giờ, thu âm nghe lại một lần.

    ### Action
    - [ ] Trình bày thử với một người ngoài ngành — họ nêu lại được đề nghị của bạn thì đạt.

    ## L5-04 · CV, portfolio & phỏng vấn BA

    **Mục tiêu:** Đóng gói artefact thành portfolio và luyện trả lời STAR.

    ### Why
    Nhà tuyển dụng không tin lời kể — họ tin artefact. Portfolio với BRD,
    BPMN, wireframe thật đáng giá hơn mọi chứng chỉ liệt kê suông.

    ### What
    - Cấu trúc portfolio: mỗi case một trang — bối cảnh, vai trò, artefact, kết quả.
    - CV cho BA chuyển ngành: dịch kinh nghiệm cũ sang ngôn ngữ phân tích.
    - Trả lời phỏng vấn tình huống theo STAR: Situation, Task, Action, Result.

    ### How
    Xem video, dựng portfolio từ artefact capstone, luyện 5 câu phỏng vấn
    thường gặp theo STAR.

    ### Action
    - [ ] Hoàn thành portfolio một trang cho capstone và bản trả lời STAR cho 3 câu hỏi phỏng vấn.

    ## L5-05 · Quiz Module 5

    Trả lời 4 câu, đạt từ 70% (3/4) để hoàn thành giáo trình.

    | # | Câu hỏi | A | B | C | D | Đáp án |
    | --- | --- | --- | --- | --- | --- | --- |
    | 1 | Bước đầu tiên khi nhận capstone case là gì? | Vẽ wireframe ngay cho ấn tượng | Phân tích vấn đề và stakeholder trước khi bàn giải pháp | Chọn công nghệ triển khai | Viết test case | B |
    | 2 | Một functional spec tốt phải thế nào? | Càng dài càng tốt | Chỉ dev đọc hiểu là được | Mô tả hành vi kiểm chứng được, gồm cả ngoại lệ | Tránh nói về thông điệp lỗi | C |
    | 3 | Portfolio BA nên chứa gì? | Danh sách chứng chỉ đã học | Artefact thật: BRD, sơ đồ quy trình, wireframe | Ảnh chụp bằng khen | Bảng điểm đại học | B |
    | 4 | Trả lời phỏng vấn tình huống nên theo cấu trúc nào? | INVEST | MoSCoW | RACI | STAR | D |
    """
}
