import SwiftUI

// MARK: - App bar (design.md §6: 44pt, surface bg, trailing CTA = accent filled)

public struct SolAppBar<Trailing: View>: View {
    let title: String
    let crumb: String?
    @ViewBuilder var trailing: Trailing

    public init(title: String, crumb: String? = nil, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.crumb = crumb
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: Sol.Spacing.s) {
            SolLogoMark()
            Text(title).font(SolFont.barTitle()).foregroundStyle(SolColor.textPrimary)
            if let crumb {
                Text(crumb).font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
            }
            Spacer(minLength: Sol.Spacing.s)
            trailing
        }
        .padding(.horizontal, Sol.Spacing.l)
        .frame(height: Sol.Chrome.appBar)
        .background(SolColor.surface)
        .overlay(alignment: .bottom) { Divider().overlay(SolColor.border) }
    }
}

/// Logo mark placeholder — uses provided marks only; never stretch/recolor (design.md §5).
public struct SolLogoMark: View {
    public init() {}
    public var body: some View {
        Text("S")
            .font(.custom("BeVietnamPro-Bold", size: 12, relativeTo: .caption))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(
                LinearGradient(colors: [Color(hex: 0xFF8A00), Color(hex: 0xD85A0B)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .accessibilityLabel("Sol")
    }
}

// MARK: - Primary button (design.md §6: accent fill, radius 9, pressed → accent.strong)

public struct SolPrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SolFont.labelStrong())
            .foregroundStyle(.white)
            .padding(.horizontal, 13).padding(.vertical, 7)
            .background(configuration.isPressed ? SolColor.accentStrong : SolColor.accent,
                        in: RoundedRectangle(cornerRadius: Sol.Radius.control))
    }
}

// MARK: - Status chip (design.md §6: pill, dot positive/warning/offline)

public enum SolSyncState {
    case synced, syncing, offline

    var dotColor: Color {
        switch self {
        case .synced: SolColor.positive
        case .syncing: Color(hex: 0xFF8A00)
        case .offline: Color(hex: 0x6B7280)
        }
    }
}

public struct SolStatusChip: View {
    let text: String
    let state: SolSyncState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    public init(_ text: String, state: SolSyncState) {
        self.text = text
        self.state = state
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle().fill(state.dotColor)
                .frame(width: 7, height: 7)
                .opacity(state == .syncing && pulsing ? 0.25 : 1)
                .onAppear {
                    // Sanctioned ambient motion (§7); disabled under Reduce Motion.
                    guard state == .syncing, !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 0.5).repeatForever()) { pulsing = true }
                }
            Text(text).font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
        .overlay(Capsule().strokeBorder(SolColor.border))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Document card (design.md §6)

public struct SolDocumentCard: View {
    let fileTag: String
    let title: String
    let meta: String
    @State private var hovering = false

    public init(fileTag: String, title: String, meta: String) {
        self.fileTag = fileTag
        self.title = title
        self.meta = meta
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Sol.Spacing.xs) {
            Text(fileTag).font(SolFont.mono().weight(.semibold)).foregroundStyle(SolColor.accentStrong)
            Text(title).font(SolFont.subheading()).foregroundStyle(SolColor.textPrimary)
                .lineLimit(2).multilineTextAlignment(.leading)
            Spacer(minLength: Sol.Spacing.s)
            Text(meta).font(SolFont.data()).foregroundStyle(SolColor.textSecondary)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SolColor.surface, in: RoundedRectangle(cornerRadius: Sol.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Sol.Radius.card)
            .strokeBorder(hovering ? SolColor.accent : SolColor.border))
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: Sol.Motion.micro), value: hovering)
    }
}

// MARK: - Segmented control (mockup `.seg`)

public struct SolSegmentedControl: View {
    let options: [String]
    @Binding var selection: Int

    public init(options: [String], selection: Binding<Int>) {
        self.options = options
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                Button(options[i]) { selection = i }
                    .font(SolFont.label())
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(selection == i ? SolColor.textPrimary : .clear)
                    .foregroundStyle(selection == i ? SolColor.bg : SolColor.textSecondary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(SolColor.border))
    }
}

// MARK: - Conflict banner (design.md §6: warning tint + burnt text, names the file, sunrise + ghost actions)

public struct SolConflictBanner: View {
    let message: AttributedString
    let primaryAction: (String, () -> Void)
    let dismissAction: (String, () -> Void)

    public init(message: AttributedString,
                primaryAction: (String, () -> Void),
                dismissAction: (String, () -> Void)) {
        self.message = message
        self.primaryAction = primaryAction
        self.dismissAction = dismissAction
    }

    public var body: some View {
        HStack(spacing: Sol.Spacing.s) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(SolColor.accentStrong)
            Text(message).font(SolFont.label()).foregroundStyle(SolColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(primaryAction.0, action: primaryAction.1)
                .font(SolFont.labelStrong()).foregroundStyle(Color(hex: 0x3A2000))
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Color(hex: 0xFF8A00), in: RoundedRectangle(cornerRadius: 7))
            Button(dismissAction.0, action: dismissAction.1)
                .font(SolFont.labelStrong()).foregroundStyle(SolColor.accentStrong)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(SolColor.accentStrong.opacity(0.5)))
        }
        .padding(10)
        .background(SolColor.warningTint, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: 0xFF8A00).opacity(0.55)))
    }
}

// MARK: - Toast

public struct SolToast: View {
    let text: String
    public init(_ text: String) { self.text = text }
    public var body: some View {
        Text(text)
            .font(SolFont.label()).foregroundStyle(Color(hex: 0xF3EBE0))
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color(hex: 0x191512), in: Capsule())
            .shadow(color: .black.opacity(Sol.Elevation.overlayOpacity),
                    radius: Sol.Elevation.overlayRadius / 2, y: Sol.Elevation.overlayY)
    }
}
