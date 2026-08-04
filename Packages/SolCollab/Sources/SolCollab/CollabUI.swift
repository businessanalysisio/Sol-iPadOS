import SwiftUI
import SolDesignSystem

/// Presence palette — design.md §2.4 (PO-approved, HR-6): self=core,
/// peers slate/violet/teal in join order.
public enum PresencePalette {
    static let peers: [Color] = [SolColor.peer1, SolColor.peer2, SolColor.peer3]

    public static func color(for member: Member, selfID: MemberID, joinIndex: Int) -> Color {
        member.id == selfID ? SolColor.accent : peers[joinIndex % peers.count]
    }
}

/// LIVE badge + avatar roster (22pt, 2pt surface ring — design.md §6).
public struct RosterView: View {
    let members: [Member]
    let selfID: MemberID
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    public init(members: [Member], selfID: MemberID) {
        self.members = members
        self.selfID = selfID
    }

    public var body: some View {
        HStack(spacing: Sol.Spacing.s) {
            HStack(spacing: 5) {
                Circle().fill(SolColor.danger).frame(width: 7, height: 7)
                    .opacity(pulse ? 0.3 : 1)
                    .onAppear {
                        guard !reduceMotion else { return } // §7: loops off under Reduce Motion
                        withAnimation(.easeInOut(duration: 0.7).repeatForever()) { pulse = true }
                    }
                Text("LIVE").font(SolFont.labelStrong()).foregroundStyle(SolColor.danger)
            }
            HStack(spacing: -6) {
                ForEach(Array(members.enumerated()), id: \.element.id) { index, m in
                    Text(String(m.displayName.prefix(1)))
                        .font(SolFont.labelStrong()).foregroundStyle(.white)
                        .frame(width: Sol.Chrome.avatar, height: Sol.Chrome.avatar)
                        .background(PresencePalette.color(for: m, selfID: selfID, joinIndex: index), in: Circle())
                        .overlay(Circle().strokeBorder(SolColor.surface, lineWidth: 2))
                        .accessibilityLabel("\(m.displayName) — \(m.role == .viewer ? "xem" : "sửa")")
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Share sheet — APP-FR-14: roles per member, default-Viewer note, and the
/// two DISTINCT actions (thu hồi link ≠ kết thúc phiên) as separate buttons.
public struct ShareSheetView: View {
    let shareURL: String
    let members: [Member]
    let onSetRole: (MemberID, MemberRole) -> Void
    let onRevokeLink: () -> Void
    let onEndSession: () -> Void

    public init(shareURL: String, members: [Member],
                onSetRole: @escaping (MemberID, MemberRole) -> Void,
                onRevokeLink: @escaping () -> Void,
                onEndSession: @escaping () -> Void) {
        self.shareURL = shareURL
        self.members = members
        self.onSetRole = onSetRole
        self.onRevokeLink = onRevokeLink
        self.onEndSession = onEndSession
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Sol.Spacing.m) {
            Text("Mời vào Live Share").font(SolFont.h2()).foregroundStyle(SolColor.textPrimary)
            HStack {
                Text(shareURL).font(SolFont.data()).foregroundStyle(SolColor.textPrimary)
                Spacer()
                Button("Sao chép") { UIPasteboard.general.string = shareURL }
                    .buttonStyle(SolPrimaryButtonStyle())
            }
            Text("Link mới mở với quyền Viewer (APP-BR-01). Nội dung tài liệu sẽ được gửi qua máy chủ relay đặt tại Singapore.") // APP-BR-06 + HR-5 §10.1
                .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)

            ForEach(members) { m in
                HStack {
                    Text(m.displayName).font(SolFont.body()).foregroundStyle(SolColor.textPrimary)
                    Spacer()
                    if m.role == .owner {
                        Text("Owner").font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                    } else {
                        Picker("", selection: Binding(
                            get: { m.role },
                            set: { onSetRole(m.id, $0) }
                        )) {
                            Text("Editor").tag(MemberRole.editor)
                            Text("Viewer").tag(MemberRole.viewer)
                        }
                        .pickerStyle(.segmented).frame(width: 150)
                    }
                }
            }

            Divider().overlay(SolColor.border)
            // Hai hành vi tách biệt — APP-FR-14 (PAUL-09).
            Button("Thu hồi link (chặn người mới, không ảnh hưởng phiên)") { onRevokeLink() }
                .font(SolFont.labelStrong()).foregroundStyle(SolColor.accentStrong)
            Button("Kết thúc phiên với mọi người", role: .destructive) { onEndSession() }
                .font(SolFont.labelStrong())
        }
        .padding(Sol.Spacing.l)
        .background(SolColor.surface, in: RoundedRectangle(cornerRadius: Sol.Radius.sheet))
    }
}
