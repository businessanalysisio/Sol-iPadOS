import SwiftUI

/// Component gallery — the snapshot subject for the M0 DoD matrix
/// (2 themes × 3 split-view widths × Dynamic Type XL) and a manual QA screen.
/// Demo strings intentionally use heavy Vietnamese diacritics (ạ ả ế ệ ố ộ ớ ờ ở ư đ)
/// so any glyph regression is visible in every snapshot.
public struct DesignSystemGallery: View {
    @State private var seg = 0

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Sol.Spacing.l) {
                SolAppBar(title: "CRM B2B Logistics", crumb: "/ 02 · Đặc tả") {
                    Button("+ Tài liệu mới") {}.buttonStyle(SolPrimaryButtonStyle())
                }

                Group {
                    Text("Đặc tả — Quy trình Báo giá ưu đãi").font(SolFont.display())
                    Text("Từ vận hành sự kiện đến trí tuệ hệ sinh thái").font(SolFont.h1())
                    Text("US-12 · Tạo báo giá từ Opportunity").font(SolFont.h2())
                    Text("Ràng buộc & tiêu chí nghiệm thu").font(SolFont.subheading())
                    Text("Là nhân viên Sales, tôi muốn tạo báo giá trực tiếp để không nhập lại dữ liệu.")
                        .font(SolFont.body())
                }
                .foregroundStyle(SolColor.textPrimary)

                HStack(spacing: Sol.Spacing.s) {
                    SolStatusChip("Đã đồng bộ · vừa xong", state: .synced)
                    SolStatusChip("Đang đồng bộ 3 thay đổi…", state: .syncing)
                    SolStatusChip("Ngoại tuyến — sẽ đồng bộ khi có mạng", state: .offline)
                }

                HStack(spacing: Sol.Spacing.m) {
                    SolDocumentCard(fileTag: ".MD · FRS",
                                    title: "Quy trình Báo giá — Đặc tả chức năng",
                                    meta: "8,4k từ · Đang mở")
                    SolDocumentCard(fileTag: ".MD · BRD",
                                    title: "BRD v2 — Mục tiêu & phạm vi",
                                    meta: "5,1k từ · Hôm qua")
                }

                SolSegmentedControl(options: ["Soạn thảo", "Song song", "Preview"], selection: $seg)

                SolConflictBanner(
                    message: try! AttributedString(markdown:
                        "**Xung đột iCloud:** bản kia lưu thành **\"FRS… (conflicted copy Hảo 2026-08-02).md\"** — mọi phiên bản phát hiện được đều được bảo toàn."),
                    primaryAction: ("Xem bản sao", {}),
                    dismissAction: ("Đóng", {})
                )

                HStack(spacing: Sol.Spacing.s) {
                    ForEach(Array(SolColor.chartRamp.enumerated()), id: \.offset) { _, c in
                        RoundedRectangle(cornerRadius: 5).fill(c).frame(width: 44, height: 24)
                    }
                    Text("1.234").font(SolFont.data()).foregroundStyle(SolColor.accentStrong)
                }

                SolToast("Đã tạo Tài-liệu-chưa-đặt-tên.md")
            }
            .padding(Sol.Spacing.l)
        }
        .background(SolColor.bg)
    }
}

#Preview("Gallery · Light") { DesignSystemGallery() }
#Preview("Gallery · Dark") { DesignSystemGallery().preferredColorScheme(.dark) }
