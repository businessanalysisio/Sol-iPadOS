import Foundation

/// Chart flavor of a sol-data block.
public enum ChartType: String, Equatable {
    case bar, line, pie
}

/// One data point: label (kỳ) + value.
public struct DataPoint: Equatable {
    public let label: String
    public let value: Double
    public init(label: String, value: Double) {
        self.label = label
        self.value = value
    }
}

/// Deterministic, user-facing errors — APP-FR-09 AC: "thông báo xác định",
/// APP-BR-02: limits report clearly with a way forward.
public enum DataBlockError: Error, Equatable {
    case invalidRow(line: Int, content: String)
    case tooManyRows(limit: Int)
    case emptyData
    case unknownType(String)

    /// The exact string the preview shows (tested verbatim).
    public var message: String {
        switch self {
        case .invalidRow(let line, let content):
            return "Không đọc được CSV — cần dạng `W1,120` (dòng lỗi đầu tiên: \(line): “\(content)”)"
        case .tooManyRows(let limit):
            return "CSV vượt giới hạn \(limit) dòng (APP-BR-02). Hãy tách nhỏ dữ liệu hoặc liên kết file đã tổng hợp."
        case .emptyData:
            return "Chưa có dữ liệu — thêm các dòng dạng `W1,120` vào block."
        case .unknownType(let t):
            return "Loại chart “\(t)” không hỗ trợ — dùng bar, line hoặc pie."
        }
    }
}

/// A parsed, render-ready sol-data block.
public struct DataBlockSpec: Equatable {
    public let type: ChartType
    public let title: String?
    public let sourcePath: String? // src=data/x.csv — resolved by the caller
    public let points: [DataPoint]
}

public enum DataBlockParser {
    /// APP-BR-02: CSV data block ≤ 10.000 dòng.
    public static let maxRows = 10_000

    /// True if a fence's info string marks a sol-data block.
    public static func isSolData(info: String) -> Bool {
        info == "sol-data" || info.hasPrefix("sol-data ") || info.hasPrefix("sol-data\t")
    }

    /// Parses the fence info string + body lines into a spec.
    /// `info` example: `sol-data type=bar title="Yêu cầu báo giá/tuần"`.
    public static func parse(info: String, body: [String]) -> Result<DataBlockSpec, DataBlockError> {
        let attrs = attributes(of: info)

        let type: ChartType
        if let raw = attrs["type"] {
            guard let t = ChartType(rawValue: raw) else { return .failure(.unknownType(raw)) }
            type = t
        } else {
            type = .bar
        }

        let sourcePath = attrs["src"]

        switch parseCSV(body) {
        case .failure(let e):
            // A src= block may legitimately have an empty body.
            if case .emptyData = e, sourcePath != nil {
                return .success(DataBlockSpec(type: type, title: attrs["title"], sourcePath: sourcePath, points: []))
            }
            return .failure(e)
        case .success(let points):
            return .success(DataBlockSpec(type: type, title: attrs["title"], sourcePath: sourcePath, points: points))
        }
    }

    /// CSV body → points. First row with a non-numeric value column is
    /// tolerated as a header (mockup: `week,count`); any later bad row is a
    /// hard error carrying its 1-based line number.
    public static func parseCSV(_ lines: [String]) -> Result<[DataPoint], DataBlockError> {
        var points: [DataPoint] = []
        var sawDataOrHeader = false
        for (idx, raw) in lines.enumerated() {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            guard points.count < maxRows else { return .failure(.tooManyRows(limit: maxRows)) }

            let parts = line.split(separator: ",", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            if parts.count == 2, let value = Double(parts[1]) {
                points.append(DataPoint(label: parts[0], value: value))
                sawDataOrHeader = true
            } else if !sawDataOrHeader {
                sawDataOrHeader = true // header row (e.g. "week,count") — skip once
            } else {
                return .failure(.invalidRow(line: idx + 1, content: line))
            }
        }
        return points.isEmpty ? .failure(.emptyData) : .success(points)
    }

    /// key=value attributes; values may be double-quoted (spaces allowed).
    static func attributes(of info: String) -> [String: String] {
        var attrs: [String: String] = [:]
        var i = info.startIndex
        while i < info.endIndex {
            guard let eq = info[i...].firstIndex(of: "=") else { break }
            // key = word ending at '='
            let keyStart = info[i..<eq].lastIndex(of: " ").map(info.index(after:)) ?? i
            let key = String(info[keyStart..<eq]).trimmingCharacters(in: .whitespaces)
            var valStart = info.index(after: eq)
            guard valStart < info.endIndex else { break }
            let value: String
            if info[valStart] == "\"" {
                valStart = info.index(after: valStart)
                let valEnd = info[valStart...].firstIndex(of: "\"") ?? info.endIndex
                value = String(info[valStart..<valEnd])
                i = valEnd < info.endIndex ? info.index(after: valEnd) : info.endIndex
            } else {
                let valEnd = info[valStart...].firstIndex(of: " ") ?? info.endIndex
                value = String(info[valStart..<valEnd])
                i = valEnd
            }
            if !key.isEmpty { attrs[key] = value }
        }
        return attrs
    }
}
