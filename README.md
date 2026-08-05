# Sol — The Analyst's Workspace (iPadOS)

Client native iPadOS của nền tảng SOL (Second Brain & Knowledge Infrastructure, sol.io.vn).

**Hồ sơ quản trị:** Kế hoạch (`SOL-iPadOS-App-Development-Plan-v1.0.md`) · Biên bản KG-BA Council + re-review. **Tài liệu canonical trong repo:** [`docs/PRD-Sol-iPadOS-App-v1.1.md`](docs/PRD-Sol-iPadOS-App-v1.1.md) (PRD baseline **v1.2.1**, tái lập vào repo 05/08/2026 — bản `E:\Documents` chỉ còn giá trị đối chiếu) · [`docs/design.md`](docs/design.md) (ADR-D07/D08) · [`docs/sol_ipados_mockups_v3.2_orange.html`](docs/sol_ipados_mockups_v3.2_orange.html) (mockup tương tác — đủ 7 màn hình, gồm S7 Settings) · [`docs/relay-service-spec-v0.1.md`](docs/relay-service-spec-v0.1.md) (v1.0, HR-5 đã duyệt).

## Trạng thái milestone (04/08/2026)

| Milestone | Trạng thái | Nội dung chính |
|---|---|---|
| **M0** — Design System | ✅ Code + CI xanh | Token §2.2–2.4, typography Be Vietnam Pro (ADR-D08, verify 134/134 glyph VN), components §6, contrast §2.5 trong CI. **Còn: record snapshot baseline trên Mac** |
| **M1** — Workspace + Store | ✅ Code + CI xanh | FTS5 + fold đ/Đ (Phụ lục C), 4 trạng thái iCloud + fallback local (APP-FR-15/AC-09), Thùng rác + purge cascade (APP-FR-17/AC-08), ⌘K palette danh sách đóng Phụ lục A |
| **M2** — Editor + Block Model | ✅ Code + CI xanh | Parser byte-engine UTF-8 một-lượt (gutter = product truth theo cấu trúc), ~33ms/10k từ Debug sau 3 vòng perf-tripwire, journal-before-write + kill-app recovery, version metadata (actor/timestamp/operation) |
| **M3** — Data Blocks | ✅ Code + CI xanh | `sol-data` → Swift Charts (ramp §2.3), lỗi CSV đúng-nguyên-văn-PRD, downsample ≤200 điểm + ghi chú N/M, insight per-type, VoiceOver ≤25/summary |
| **M4** — Sync + Conflict | ✅ Lớp 1, CI xanh | ConflictResolver không-merge (tên file khớp APP-BR-03 nguyên văn), SyncEngine protocol + chip 3 trạng thái, multi-window + resolve 2 cửa sổ (M-01). **Còn Lớp 2:** NSFileVersion monitor + e2e iCloud 2 thiết bị (gate APP-AC-03) |
| **M5** — Live Share | ✅ Lớp 1, CI xanh | SolCollab: TextCRDT (RGA + causal buffering, fuzz 3-actor hội tụ), MockRelayHub = executable reference của SPEC-RELAY §4 (state machine 8 hàng, timer 15' clock-inject, Viewer chặn tại relay). **KHÔNG link vào app v1 (HR-2).** Còn: `CloudflareCollabTransport` khi relay staging (tuần 10) |
| Settings (APP-FR-16) | ✅ Hoàn chỉnh | Theme instant, ngôn ngữ + restart notice, phím tắt từ nguồn danh sách đóng, telemetry 2 lớp cưỡng chế bằng type system (APP-NFR-08) |
| **M6** — Hoàn thiện | ⬜ Chưa bắt đầu | A11y audit Phụ lục D, perf Release trên thiết bị, TestFlight |

**Sổ quyết định PO: 6/6 đã chốt** — HR-1 Be Vietnam Pro · HR-2 Live Share=v1.1 · HR-3 Confidential (cảnh báo relay+SIN, không label v1) · HR-4 iPadOS 17/iPad gen 10 · HR-5 relay=Cloudflare Durable Objects · HR-6 presence palette. 4 CR (D1/D2/D3/M1) đã áp.

## Cấu trúc

```
Sol-iPadOS/
├── project.yml                # XcodeGen — iPad-only, iPadOS 17, multi-window, iCloud entitlements
├── App/SolApp.swift           # WindowGroup chính + WindowGroup(for: Document) (multi-window M4)
├── Packages/
│   ├── SolDesignSystem/       # tokens, typography, components (+ Gallery = snapshot subject)
│   ├── SolStore/              # DocumentStore, FTS (đ/Đ), WorkspaceLocation, Trash/purge,
│   │                          # Journal/Version, SyncEngine, ConflictResolver, Telemetry
│   ├── SolBlockModel/         # parser Markdown byte-engine — 1 lượt ra preview tree + gutter tags
│   ├── SolEditor/             # màn S2: TextKit 2 + gutter theo layout fragment + toolbar
│   ├── SolDataBlocks/         # màn S3: sol-data → Swift Charts + insight + VoiceOver
│   ├── SolWorkspace/          # màn S1 + Thùng rác + ⌘K palette + Settings
│   └── SolCollab/             # màn S4 (v1.1): CRDT + relay mock + roster/share sheet — NGOÀI app v1
├── docs/                      # PRD v1.2.1, design.md, mockups v3.2 (tương tác, 7 màn), relay spec (canonical)
└── .github/workflows/ci.yml   # macos-15, tự provision simulator iPad gen 10 (HR-4)
```

17 test suite / ~95 test chạy trên simulator iPad (10th generation) mỗi lần push.

## Thiết lập trên Mac (lần đầu)

```bash
brew install xcodegen
xcodegen generate
open Sol.xcodeproj
```

1. **Record snapshot baseline** (việc Mac đầu tiên, mở khóa matrix M0): chạy test suite `SolDesignSystemTests` trên simulator **iPad (10th generation) / iPadOS 17** với `withSnapshotTesting(record: .all)` (hoặc env `SNAPSHOT_RECORD=1`), commit thư mục `__Snapshots__/`. SnapshotTests hiện **skip có chủ đích** khi chưa có baseline — CI vẫn có nghĩa, không đỏ giả.
2. Lớp 2 (ADR-A03, cần thiết bị thật): e2e iCloud 2 iPad (kịch bản vàng APP-AC-03), đo keystroke→preview p95 Release trên iPad gen 10 (APP-NFR-01), wiring `NSFileVersion` monitor → `ConflictResolver`.

## Quy ước (đúc từ chính lịch sử repo này)

- **Không tin dấu xanh CI qua pipe** — 2 run đầu tiên của repo là xanh giả (`xcodebuild | xcbeautify` thiếu `pipefail` nuốt lỗi). `pipefail` trong workflow là load-bearing; xác minh bằng dòng `** TEST SUCCEEDED **` trong log.
- **Perf tripwire không được nâng số** — chỉ được tối ưu code hoặc leo thang sang incremental splicing (comment trong `PerformanceTests.swift`); estimator là **min-of-N** vì runner chia sẻ có scheduler stall hàng trăm ms.
- **Không hard-code màu/chữ/spacing** — chỉ `SolColor`/`SolFont`/`Sol.*` (APP-BR-05). ADR-M0-01: token là code constants, không .xcassets.
- Mã yêu cầu khi tham chiếu chéo dùng tiền tố `APP-`/`PLT-` (ADR-A01 rev.2).
- Telemetry: sự kiện mới bắt buộc qua enum `TelemetryEvent` — schema chỉ chứa số, không tồn tại field chở được nội dung (APP-NFR-08).
- SolCollab giữ ngoài dependency của app target đến phát hành v1.1 (HR-2) — `project.yml` có comment đánh dấu.

## Lộ trình còn lại

1. **Mac pass:** snapshot baseline → CI mở matrix đầy đủ.
2. **Tuần 8–10:** A3 build relay theo [`docs/relay-service-spec-v0.1.md`](docs/relay-service-spec-v0.1.md) — `MockRelayHub.swift` là bản tham chiếu hành vi; transport thật phải buffer frame trước-handler như mock (ghi chú in-source).
3. **Thiết bị thật:** đóng gate APP-AC-03 Lớp 2 + perf Release (M4/M6).
4. **M6:** a11y audit theo Phụ lục D PRD, TestFlight beta, App Store v1 (không gồm Live Share).
