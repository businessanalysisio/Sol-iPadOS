import Foundation

/// Sinh tài liệu "03 · Dashboard" từ danh sách BacklogItem — thay bản seed
/// tĩnh bằng roll-up thật ngay lần đổi status đầu tiên. Đầu ra là markdown
/// + sol-data thường, render qua pipeline M2/M3 như mọi tài liệu khác.
public enum DashboardRenderer {
    /// H1 nhận diện tài liệu Dashboard — PHẢI khớp bản seed để lần cập nhật
    /// đầu tiên tìm đúng file mà ghi đè.
    public static let marker = "# BA Bootcamp — Production Dashboard"

    /// Thứ tự sprint theo lịch (dòng thời gian 2026). Sprint lạ (người dùng
    /// thêm) xếp sau, theo thứ tự xuất hiện.
    static let sprintOrder = [
        "S0 · Foundations", "S1 · Core Build I", "S2 · Core Build II",
        "S3 · Complete Build", "Beta Cohort", "S4 · Iterate & Launch",
    ]

    public static func render(items: [BacklogItem]) -> String {
        let total = Rollup(items)
        var out = """
        \(marker)

        Roll-up tự động từ Backlog qua Bootcamp Board — % done tính theo số item Done. \
        Tổng thể: **\(total.doneItems)/\(total.items) items · \(total.doneEffort)/\(total.effort) person-days · \(total.pct)**.

        ## By status

        | Status | Items | Effort (days) |
        | --- | --- | --- |

        """
        for status in BacklogStatus.allCases {
            let r = Rollup(items.filter { $0.status == status })
            out += "| \(status.rawValue) | \(r.items) | \(r.effort) |\n"
        }
        out += """

        ```sol-data type=pie title="Items theo trạng thái"
        status,items

        """
        for status in BacklogStatus.allCases {
            let n = items.filter { $0.status == status }.count
            if n > 0 { out += "\(status.rawValue),\(n)\n" }
        }
        out += """
        ```

        ## By track

        | Track | Items | Done | Effort (days) | Effort done | % Done |
        | --- | --- | --- | --- | --- | --- |

        """
        let tracks = ordered(items.map(\.track))
        for track in tracks {
            out += row(track, Rollup(items.filter { $0.track == track }))
        }
        out += row("TOTAL", total)
        out += """

        ```sol-data type=bar title="Effort (days) theo track"
        track,days

        """
        for track in tracks {
            out += "\(track),\(Rollup(items.filter { $0.track == track }).effort)\n"
        }
        out += """
        ```

        ## By priority (MoSCoW)

        | Priority | Items | Done | Effort (days) | Effort done | % Done |
        | --- | --- | --- | --- | --- | --- |

        """
        for priority in ordered(items.map(\.priority)) {
            out += row(priority, Rollup(items.filter { $0.priority == priority }))
        }
        out += """

        ## By sprint

        | Sprint | Items | Done | Effort (days) | Effort done | % Done |
        | --- | --- | --- | --- | --- | --- |

        """
        let sprints = ordered(items.map(\.sprint)).sorted {
            (sprintOrder.firstIndex(of: $0) ?? .max) < (sprintOrder.firstIndex(of: $1) ?? .max)
        }
        for sprint in sprints {
            out += row(sprint, Rollup(items.filter { $0.sprint == sprint }))
        }
        out += """

        ```sol-data type=line title="Effort (days) theo sprint"
        sprint,days

        """
        for sprint in sprints {
            out += "\(sprint),\(Rollup(items.filter { $0.sprint == sprint }).effort)\n"
        }
        out += "```\n"
        return out
    }

    // MARK: - Private

    private struct Rollup {
        let items: Int, doneItems: Int, effort: Int, doneEffort: Int
        init(_ list: [BacklogItem]) {
            items = list.count
            effort = list.reduce(0) { $0 + $1.effortDays }
            let done = list.filter { $0.status == .done }
            doneItems = done.count
            doneEffort = done.reduce(0) { $0 + $1.effortDays }
        }
        /// % done theo item, làm tròn thường; nhóm rỗng đọc là 0%.
        var pct: String {
            items == 0 ? "0%" : "\(Int((Double(doneItems) * 100 / Double(items)).rounded()))%"
        }
    }

    private static func row(_ name: String, _ r: Rollup) -> String {
        "| \(name) | \(r.items) | \(r.doneItems) | \(r.effort) | \(r.doneEffort) | \(r.pct) |\n"
    }

    /// Giá trị duy nhất theo thứ tự xuất hiện đầu tiên.
    private static func ordered(_ values: [String]) -> [String] {
        var seen = Set<String>(), out: [String] = []
        for v in values where seen.insert(v).inserted { out.append(v) }
        return out
    }
}
