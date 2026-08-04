import SwiftUI
import SolBlockModel
import SolDataBlocks
import SolDesignSystem

/// Block gutter — APP-FR-07 (signature, "product truth"). Renders one tag per
/// logical line at the y-position TextKit 2 reported for that line's fragment;
/// scrolls in lockstep with the editor via the shared offset.
struct GutterView: View {
    let lineTypes: [BlockType]
    let fragments: [LineFragment]
    let scrollOffset: CGFloat

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                ForEach(fragments, id: \.lineIndex) { frag in
                    if frag.lineIndex < lineTypes.count {
                        let type = lineTypes[frag.lineIndex]
                        Text(type.rawValue)
                            .font(SolFont.mono().weight(.semibold))
                            .foregroundStyle(type.isStructural ? SolColor.accent : SolColor.textSecondary)
                            .frame(width: Sol.Chrome.gutterRail, alignment: .center)
                            .offset(y: frag.y - scrollOffset)
                            .accessibilityHidden(true) // mirrored info; VoiceOver reads content
                    }
                }
            }
        }
        .frame(width: Sol.Chrome.gutterRail)
        .background(SolColor.surfaceAlt)
        .overlay(alignment: .trailing) { Divider().overlay(SolColor.border) }
        .clipped()
        .accessibilityLabel("Gutter phân loại block")
    }
}

/// Live preview — renders the Block Model tree (never re-parses on its own:
/// one parser, one truth).
struct PreviewView: View {
    let blocks: [Block]
    /// Resolves `src=…` of sol-data blocks to CSV text (workspace-relative).
    var resolveCSV: ((String) -> String?)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Sol.Spacing.s) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    render(block)
                }
            }
            .padding(Sol.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(SolColor.surface)
    }

    @ViewBuilder
    private func render(_ block: Block) -> some View {
        switch block {
        case .heading(let level, let content):
            if level == 1 {
                Text(attributed(content)).font(SolFont.h1()).foregroundStyle(SolColor.textPrimary)
            } else {
                Text(attributed(content)).font(SolFont.h2()).foregroundStyle(SolColor.textPrimary)
                    .padding(.leading, Sol.Spacing.s)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(SolColor.accent).frame(width: 3) // §4: 3pt accent rule
                    }
            }
        case .paragraph(let content):
            Text(attributed(content)).font(SolFont.body()).foregroundStyle(SolColor.textPrimary)
        case .quote(let content):
            Text(attributed(content)).font(SolFont.body()).foregroundStyle(SolColor.textPrimary)
                .padding(Sol.Spacing.s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SolColor.bg)
                .overlay(alignment: .leading) { Rectangle().fill(SolColor.border).frame(width: 3) }
        case .list(let items):
            VStack(alignment: .leading, spacing: Sol.Spacing.xs) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: Sol.Spacing.s) {
                        Text("•").foregroundStyle(SolColor.accentStrong)
                        Text(attributed(item)).font(SolFont.body()).foregroundStyle(SolColor.textPrimary)
                    }
                }
            }
        case .table(let header, let rows):
            // design.md §6: header burnt bg + cream text, zebra rows.
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    ForEach(Array(header.enumerated()), id: \.offset) { _, cell in
                        Text(attributed(cell)).font(SolFont.labelStrong())
                            .foregroundStyle(Color(hex: 0xF8F2EA))
                            .padding(Sol.Spacing.s).frame(maxWidth: .infinity, alignment: .leading)
                            .background(SolColor.accentStrong)
                    }
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Text(attributed(cell)).font(SolFont.body())
                                .foregroundStyle(SolColor.textPrimary)
                                .padding(Sol.Spacing.s).frame(maxWidth: .infinity, alignment: .leading)
                                .background(rowIndex.isMultiple(of: 2) ? SolColor.surface : SolColor.surfaceAlt)
                        }
                    }
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(SolColor.border))
        case .fence(let info, let body):
            if DataBlockParser.isSolData(info: info) {
                // M3 (APP-FR-09): sol-data fences render as live charts.
                DataBlockView(info: info, body: body, resolveCSV: resolveCSV)
            } else {
                VStack(alignment: .leading, spacing: Sol.Spacing.xs) {
                    Text(info.isEmpty ? "code" : info)
                        .font(SolFont.data()).foregroundStyle(SolColor.accentStrong)
                    ForEach(Array(body.enumerated()), id: \.offset) { _, line in
                        Text(line).font(SolFont.mono()).foregroundStyle(SolColor.textPrimary)
                    }
                }
                .padding(Sol.Spacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SolColor.bg, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func attributed(_ inlines: [Inline]) -> AttributedString {
        var out = AttributedString()
        for inline in inlines {
            switch inline {
            case .text(let s): out += AttributedString(s)
            case .bold(let s):
                var a = AttributedString(s); a.inlinePresentationIntent = .stronglyEmphasized; out += a
            case .italic(let s):
                var a = AttributedString(s); a.inlinePresentationIntent = .emphasized; out += a
            case .code(let s):
                var a = AttributedString(s); a.inlinePresentationIntent = .code
                a.foregroundColor = SolColor.accentStrong; out += a
            }
        }
        return out
    }
}
