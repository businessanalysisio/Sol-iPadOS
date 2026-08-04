# Sol — The Analyst's Workspace (iPadOS)

Client native iPadOS của SOL Core. Baseline yêu cầu: **PRD-Sol-iPadOS-App v1.2** · Design system: **design.md (ADR-D07/D08)** · Kế hoạch: **SOL-iPadOS-App-Development-Plan v1.0**.

## Trạng thái: M0 — Foundation

| Hạng mục M0 | Trạng thái |
|---|---|
| Cấu trúc project + SPM (kế hoạch §2.3) | ✅ SolDesignSystem; các package khác thêm dần từ M1 |
| Token màu §2.2 + ramp §2.3 + presence §2.4 | ✅ `Tokens/SolColor.swift` |
| Typography §3 (Be Vietnam Pro + Inter, ADR-D08) | ✅ `Tokens/SolTypography.swift` + font bundled (đã verify 134/134 glyph VN) |
| Spacing/Radius/Chrome §4, §6 | ✅ `Tokens/SolMetrics.swift` |
| Components §6 | ✅ AppBar, PrimaryButton, StatusChip, DocumentCard, SegControl, ConflictBanner, Toast + Gallery |
| Contrast assertion §2.5 (CI) | ✅ `ContrastTests.swift` (ngưỡng theo số đo thực) |
| Test glyph tiếng Việt (Phụ lục C PRD) | ✅ `VietnameseGlyphTests.swift` |
| Snapshot 2 theme × 3 split × DT XL (CR-D1) | ✅ `SnapshotTests.swift` — **cần record baseline lần đầu trên Mac** |
| CI (GitHub Actions, iPad gen 10 sim) | ✅ `.github/workflows/ci.yml` |

## Thiết lập trên Mac (lần đầu)

```bash
brew install xcodegen
xcodegen generate          # sinh Sol.xcodeproj
open Sol.xcodeproj
```

1. Chạy test lần đầu để **record snapshot baseline** trên simulator **iPad (10th generation) / iPadOS 17** (reference device — HR-4): đặt env `SNAPSHOT_RECORD=1` hoặc dùng `withSnapshotTesting(record: .all)`, chạy `⌘U`, rồi commit thư mục `__Snapshots__`.
2. Các lần sau: `⌘U` bình thường — mọi drift pixel/contrast/glyph sẽ fail.

## Quy ước

- **Không hard-code màu/chữ/spacing** — chỉ dùng `SolColor` / `SolFont` / `Sol.Spacing…` (APP-BR-05; PR vi phạm bị chặn ở review).
- Mã yêu cầu tham chiếu chéo dùng tiền tố `APP-` / `PLT-` (ADR-A01 rev.2).
- Snapshot chỉ chạy/record trên đúng reference simulator — khác máy khác kết quả.
- ADR-M0-01 (ghi trong `SolColor.swift`): token màu là code constants + dynamic provider thay vì asset catalog — cùng contract tên với design.md §9, một nguồn sự thật, test được trong CI. Nêu lại với A1 nếu design tooling cần .xcassets.

## Cấu trúc

```
Sol-iPadOS/
├── project.yml                    # XcodeGen — iPad-only, iPadOS 17, multi-window
├── App/SolApp.swift               # Shell M0 = DesignSystemGallery; M1 thay bằng Workspace
├── Packages/SolDesignSystem/
│   ├── Sources/SolDesignSystem/
│   │   ├── Tokens/                # SolColor, SolTypography (+FontRegistrar), SolMetrics
│   │   ├── Components/            # SolComponents + DesignSystemGallery
│   │   └── Resources/Fonts/       # BeVietnamPro M/SB/B + Inter R/M/SB (OFL)
│   └── Tests/SolDesignSystemTests # Contrast · VietnameseGlyph · Snapshot
└── .github/workflows/ci.yml
```

## Tiếp theo (M1 — Workspace + Store, kế hoạch §3)

`SolStore` (iCloud container + fallback local APP-FR-15, FTS5 fold đ/Đ, Thùng rác APP-FR-17), `SolWorkspace` (browser, search, ⌘K palette Phụ lục A), chip "Đã lưu cục bộ".
