import Foundation

/// Display-side downsampling — APP-FR-09 (M-04): charts render at most 200
/// points; the chart notes "hiển thị N/M điểm" when it downsamples.
public struct DisplaySeries: Equatable {
    public let points: [DataPoint]
    public let totalCount: Int
    public var isDownsampled: Bool { points.count < totalCount }
    public var note: String? {
        isDownsampled ? "hiển thị \(points.count)/\(totalCount) điểm" : nil
    }
}

public enum Downsampler {
    public static let maxDisplayPoints = 200

    /// Bucket-mean to ≤200 points; first and last points survive exactly
    /// (they anchor the insight and the axis).
    public static func downsample(_ points: [DataPoint],
                                  to limit: Int = maxDisplayPoints) -> DisplaySeries {
        guard points.count > limit, limit >= 3 else {
            return DisplaySeries(points: points, totalCount: points.count)
        }
        var out: [DataPoint] = [points[0]]
        let innerLimit = limit - 2
        let inner = points[1..<(points.count - 1)]
        let bucketSize = Double(inner.count) / Double(innerLimit)
        for b in 0..<innerLimit {
            let start = inner.startIndex + Int(Double(b) * bucketSize)
            let end = min(inner.startIndex + Int(Double(b + 1) * bucketSize), inner.endIndex)
            guard start < end else { continue }
            let bucket = inner[start..<end]
            let mean = bucket.reduce(0) { $0 + $1.value } / Double(bucket.count)
            out.append(DataPoint(label: bucket.first!.label, value: mean))
        }
        out.append(points[points.count - 1])
        return DisplaySeries(points: out, totalCount: points.count)
    }
}

/// Auto-insight per chart type — PRD APP-FR-09 (EMMA-06 resolution):
/// bar/line = % change of the last two periods; pie = largest share;
/// insufficient data = nil (the line is hidden, never guessed).
public enum InsightGenerator {
    public static func insight(for type: ChartType, points: [DataPoint]) -> String? {
        switch type {
        case .bar, .line:
            guard points.count >= 2 else { return nil }
            let prev = points[points.count - 2], last = points[points.count - 1]
            guard prev.value != 0 else { return nil } // % of zero is undefined — say nothing
            let pc = Int(((last.value - prev.value) / abs(prev.value) * 100).rounded())
            let direction = pc >= 0 ? "tăng" : "giảm"
            return "\(last.label) \(direction) \(abs(pc))% so với \(prev.label)."
        case .pie:
            guard points.count >= 2 else { return nil }
            let total = points.reduce(0) { $0 + $1.value }
            guard total > 0, let top = points.max(by: { $0.value < $1.value }) else { return nil }
            let share = Int((top.value / total * 100).rounded())
            return "\(top.label) chiếm tỷ trọng lớn nhất — \(share)%."
        }
    }

    /// VoiceOver summary for large datasets — APP-FR-09 AC: > 25 points reads
    /// a summary (min/max/last), not thousands of values.
    public static func accessibilitySummary(points: [DataPoint]) -> String {
        guard let first = points.first, let last = points.last,
              let minP = points.min(by: { $0.value < $1.value }),
              let maxP = points.max(by: { $0.value < $1.value }) else {
            return "Không có dữ liệu"
        }
        return "Chuỗi \(points.count) điểm từ \(first.label) đến \(last.label). " +
               "Thấp nhất \(minP.label): \(Int(minP.value)). Cao nhất \(maxP.label): \(Int(maxP.value)). " +
               "Điểm cuối \(last.label): \(Int(last.value))."
    }

    public static let voiceOverPerValueLimit = 25
}
