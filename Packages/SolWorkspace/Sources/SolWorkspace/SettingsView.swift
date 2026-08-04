import SwiftUI
import SolStore
import SolDesignSystem

/// Màn Settings — APP-FR-16, đủ 6 mục của PRD: phím tắt (Phụ lục A), theme,
/// Thùng rác, ngôn ngữ UI, telemetry (APP-NFR-08), phiên bản/giấy phép font.
public struct SettingsView: View {
    @Bindable var settings: SettingsStore
    let openTrash: () -> Void
    @Environment(\.dismiss) private var dismiss

    public init(settings: SettingsStore, openTrash: @escaping () -> Void) {
        self.settings = settings
        self.openTrash = openTrash
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: Giao diện — hiệu lực NGAY (AC), không restart
                Section("Giao diện") {
                    Picker("Theme", selection: $settings.theme) {
                        ForEach(SolTheme.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: Ngôn ngữ — được phép cần restart, nhưng PHẢI báo (AC)
                Section("Ngôn ngữ") {
                    Picker("Ngôn ngữ giao diện", selection: $settings.language) {
                        ForEach(SolLanguage.allCases) { Text($0.label).tag($0) }
                    }
                    if settings.restartNeededForLanguage {
                        Label("Ngôn ngữ mới áp dụng sau khi khởi động lại Sol.",
                              systemImage: "arrow.triangle.2.circlepath")
                            .font(SolFont.label()).foregroundStyle(SolColor.accentStrong)
                    }
                }

                // MARK: Phím tắt — render từ CHÍNH nguồn danh sách đóng
                Section("Phím tắt (Phụ lục A — danh sách đóng)") {
                    ForEach(SolCommandID.allCases) { cmd in
                        shortcutRow(cmd.title + (cmd.availableInM1 ? "" : "  ·  từ M2+"),
                                    cmd.shortcutLabel ?? "—")
                    }
                    ForEach(NonPaletteShortcuts.all, id: \.keys) { item in
                        shortcutRow(item.action, item.keys)
                    }
                }

                // MARK: Thùng rác → APP-FR-17
                Section("Dữ liệu") {
                    Button {
                        dismiss()
                        openTrash()
                    } label: {
                        Label("Mở Thùng rác (khôi phục trong 30 ngày)", systemImage: "trash")
                            .foregroundStyle(SolColor.textPrimary)
                    }
                }

                // MARK: Telemetry — hai lớp APP-NFR-08, mặc định BẬT lớp 1
                Section {
                    Toggle("Gửi dữ liệu vận hành (Lớp 1)", isOn: $settings.telemetryEnabled)
                    Button("Xóa toàn bộ log telemetry trên máy", role: .destructive) {
                        settings.telemetry?.eraseAll()
                    }
                } header: {
                    Text("Telemetry")
                } footer: {
                    Text("""
                    Lớp 1 (đang \(settings.telemetryEnabled ? "BẬT" : "TẮT")): crash report và số đếm vận hành — thời lượng sync, mã lỗi, số tài liệu có xung đột. Chỉ là con số, đếm ngay trên máy. Tắt có hiệu lực từ sự kiện kế tiếp.
                    Lớp 2 — KHÔNG BAO GIỜ thu trong mọi trường hợp: nội dung tài liệu, tên file, từ khóa tìm kiếm, dữ liệu CSV. Ràng buộc này nằm trong cấu trúc sự kiện, không phải lời hứa.
                    """)
                    .font(SolFont.label())
                }

                // MARK: Giới thiệu
                Section("Giới thiệu") {
                    LabeledContent("Phiên bản",
                        value: "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                    LabeledContent("Font chữ", value: "Be Vietnam Pro · Inter — giấy phép OFL")
                    LabeledContent("Thiết kế", value: "Sol Design System (ADR-D07/D08)")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }

    private func shortcutRow(_ action: String, _ keys: String) -> some View {
        HStack {
            Text(action).font(SolFont.body()).foregroundStyle(SolColor.textPrimary)
            Spacer()
            Text(keys).font(SolFont.data()).foregroundStyle(SolColor.textSecondary)
        }
    }
}
