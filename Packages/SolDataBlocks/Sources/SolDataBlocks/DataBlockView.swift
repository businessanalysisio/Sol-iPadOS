import SwiftUI
import Charts
import SolDesignSystem

/// Renders one ```sol-data``` block: title + tag, chart, insight, or the
/// deterministic error message. Chart colors follow the design.md §2.3 ramp.
public struct DataBlockView: View {
    private let info: String
    private let body_: [String]
    /// Resolves `src=…` paths to CSV text (the editor wires this to the
    /// workspace root); nil resolver → src blocks show a hint instead.
    private let resolveCSV: ((String) -> String?)?

    public init(info: String, body: [String], resolveCSV: ((String) -> String?)? = nil) {
        self.info = info
        self.body_ = body
        self.resolveCSV = resolveCSV
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Sol.Spacing.s) {
            switch resolvedSpec() {
            case .failure(let error):
                header(tag: "sol-data")
                Text(error.message)
                    .font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
            case .success(let spec):
                let series = Downsampler.downsample(spec.points)
                header(tag: "sol-data · \(spec.type.rawValue)", title: spec.title)
                chart(spec.type, series.points)
                    .frame(height: 160)
                    .modifier(ChartAccessibility(points: series.points))
                if let note = series.note {
                    Text(note).font(SolFont.label()).foregroundStyle(SolColor.textSecondary)
                }
                if let insight = InsightGenerator.insight(for: spec.type, points: spec.points) {
                    Text(insight).font(SolFont.body()).foregroundStyle(SolColor.textPrimary)
                }
            }
        }
        .padding(Sol.Spacing.m)
        .background(SolColor.surface, in: RoundedRectangle(cornerRadius: Sol.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Sol.Radius.card).strokeBorder(SolColor.border))
    }

    private func resolvedSpec() -> Result<DataBlockSpec, DataBlockError> {
        DataBlockParser.parse(info: info, body: body_).flatMap { spec in
            guard let src = spec.sourcePath, spec.points.isEmpty else { return .success(spec) }
            guard let csv = resolveCSV?(src) else {
                return .failure(.invalidRow(line: 0, content: "src=\(src) — không đọc được file"))
            }
            return DataBlockParser.parseCSV(csv.components(separatedBy: "\n")).map {
                DataBlockSpec(type: spec.type, title: spec.title, sourcePath: src, points: $0)
            }
        }
    }

    private func header(tag: String, title: String? = nil) -> some View {
        HStack(spacing: Sol.Spacing.s) {
            if let title { Text(title).font(SolFont.subheading()).foregroundStyle(SolColor.textPrimary) }
            Text(tag)
                .font(SolFont.data()).foregroundStyle(SolColor.accentStrong)
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(SolColor.warningTint.opacity(0.9), in: Capsule())
        }
    }

    @ViewBuilder
    private func chart(_ type: ChartType, _ points: [DataPoint]) -> some View {
        switch type {
        case .bar:
            Chart(Array(points.enumerated()), id: \.offset) { _, p in
                BarMark(x: .value("Kỳ", p.label), y: .value("Giá trị", p.value))
                    .foregroundStyle(LinearGradient(
                        colors: [Color(hex: 0xFF8A00), Color(hex: 0xD85A0B)],
                        startPoint: .top, endPoint: .bottom))
                    .cornerRadius(4)
            }
        case .line:
            Chart(Array(points.enumerated()), id: \.offset) { _, p in
                LineMark(x: .value("Kỳ", p.label), y: .value("Giá trị", p.value))
                    .foregroundStyle(Color(hex: 0xD85A0B))
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineJoin: .round))
                PointMark(x: .value("Kỳ", p.label), y: .value("Giá trị", p.value))
                    .foregroundStyle(Color(hex: 0xFF8A00))
            }
        case .pie:
            Chart(Array(points.enumerated()), id: \.offset) { i, p in
                SectorMark(angle: .value("Giá trị", p.value), angularInset: 1)
                    .foregroundStyle(SolColor.chartRamp[i % SolColor.chartRamp.count])
                    .annotation(position: .overlay) {
                        Text(p.label).font(SolFont.label()).foregroundStyle(.white)
                    }
            }
        }
    }
}

/// APP-FR-09 AC: ≤ 25 points → per-value elements (Swift Charts' built-in
/// audio-graph/element support); larger → one summary utterance.
private struct ChartAccessibility: ViewModifier {
    let points: [DataPoint]

    func body(content: Content) -> some View {
        if points.count > InsightGenerator.voiceOverPerValueLimit {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(InsightGenerator.accessibilitySummary(points: points))
        } else {
            content // marks stay individually focusable
        }
    }
}
