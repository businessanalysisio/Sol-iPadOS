# PRD — Sol · The Analyst's Workspace (ứng dụng iPadOS)

| | |
|---|---|
| **Mã tài liệu** | PRD-APP-IPAD (tên file giữ nguyên `PRD-Sol-iPadOS-App-v1.1.md` theo quyết định quản trị hồ sơ) |
| **Baseline** | **v1.2.1** — v1.2 sau KG-BA Council re-review + 4 CR đã áp (CR-D1 · CR-D2 · CR-D3 · CR-M1) |
| **Trạng thái** | Đã duyệt — baseline đang thi hành (M0–M5 Lớp 1 đã xanh) |
| **Chủ sở hữu** | PO Sol |
| **Tài liệu liên quan** | [`design.md`](design.md) (ADR-D07/D08) · [`sol_ipados_mockups_v3.3_orange.html`](sol_ipados_mockups_v3.3_orange.html) · [`relay-service-spec-v0.1.md`](relay-service-spec-v0.1.md) (v1.0, HR-5) · Kế hoạch `SOL-iPadOS-App-Development-Plan-v1.0.md` |

> **Ghi chú vị trí canonical (05/08/2026):** bản PRD này được **tái lập vào repo** từ bản quản trị tại `E:\Documents\PRD-Sol-iPadOS-App-v1.1.md` cùng toàn bộ dấu vết yêu cầu trong code/test/docs của repo (cùng lý do design.md chuyển vào repo trước đó). **Từ nay sửa đổi qua git.** Một số ít mục không còn dấu vết trong repo được đánh dấu tái lập — xem §14.

**Quy ước mã (ADR-A01 rev.2):** `APP-` = yêu cầu của app iPadOS này · `PLT-` = yêu cầu nền tảng SOL (tham chiếu chéo, không định nghĩa ở đây). Danh mục: `APP-FR` chức năng · `APP-NFR` phi chức năng · `APP-BR` quy tắc nghiệp vụ · `APP-AC` nghiệm thu vàng.

---

## 1. Bối cảnh & tầm nhìn

**SOL** (sol.io.vn) là nền tảng Second Brain & Knowledge Infrastructure. App này là **client native iPadOS** của nền tảng — "The Analyst's Workspace": không gian làm việc cho chuyên viên phân tích nghiệp vụ (BA) viết đặc tả, ghi chép workshop và trình bày dữ liệu, với triết lý thương hiệu *"Intelligence that illuminates action"* và khung vận hành **C.O.D.E.** (Clarify · Organize · Define · Execute).

Lộ trình nền tảng: **GĐ1** — v1 đơn-người-dùng (PRD này) → **v1.1** — Live Share (APP-FR-13/14, HR-2) → **GĐ3** — team workspace đầy đủ (PLT-FR-13, ngoài phạm vi PRD này nhưng kiến trúc không được cản đường nó).

## 2. Phạm vi & nền tảng

- **Thiết bị:** iPad-only (`TARGETED_DEVICE_FAMILY = 2`), **iPadOS 17+**, thiết bị tham chiếu **iPad (10th generation)** — HR-4. Mọi hướng xoay; multi-window (scene riêng cho từng tài liệu).
- **Lưu trữ:** iCloud Documents (CloudDocuments entitlement) với fallback cục bộ đầy đủ tính năng (APP-FR-15, APP-NFR-04).
- **Ngôn ngữ UI:** Tiếng Việt (mặc định) + English (PRD §9 Localization; APP-FR-16).
- **Trong phạm vi v1:** S1 Workspace · S2 Editor · S3 Data Blocks · S5 Split View/Conflict · S6 Thùng rác · S7 Settings.
- **Phát hành v1.1 (code xong trước, KHÔNG link vào app v1 — HR-2):** S4 Live Share (APP-FR-13/14).
- **Ngoài phạm vi:** team workspace/identity system (GĐ3) · web/Android/macOS client · E2E encryption cho relay (hoãn theo relay spec §10) · nhãn tài liệu Confidential (HR-3: chỉ cảnh báo relay + region SIN, không label ở v1) · dashboard telemetry (kế thừa hợp đồng APP-NFR-08 ở GĐ sau).

## 3. Mục tiêu sản phẩm

| Mã | Mục tiêu | Thước đo chính |
|---|---|---|
| **G1** ① | **Tốc độ trong mạch suy nghĩ** — công cụ không bao giờ cản dòng viết của analyst | APP-NFR-01: keystroke→preview p95 ≤ 50ms (Release, thiết bị tham chiếu) |
| **G2** | **Không mất một keystroke nào** — mọi thao tác của người dùng đều sống sót qua crash, mất mạng, xung đột | Journal-before-write (APP-FR-12) · copy-then-delete khi di trú · held-ops replay & snapshot khi Live Share gián đoạn (APP-FR-13) · mọi phiên bản phát hiện được đều được bảo toàn (ADR-A03) |
| **G3** | **Trung thực** — UI không bao giờ tuyên bố điều nó không xác minh được | Chip sync chỉ nhận trạng thái có bằng chứng (APP-AC-05) · lệnh milestone sau hiển thị disabled chứ không ẩn (APP-FR-05) · thông báo iCloud đúng từng trạng thái (APP-FR-15) |
| **G4** | **Riêng tư mặc định** — dữ liệu người dùng là của người dùng | Telemetry 2 lớp cưỡng chế bằng type system (APP-NFR-08) · relay tối thiểu hóa dữ liệu, cảnh báo minh bạch (APP-BR-06, APP-NFR-03) |

## 4. Persona & bối cảnh sử dụng

1. **Chuyên viên BA** (primary — vd. "Hảo"): quản lý nhiều dự án song song (vd. workspace *CRM B2B Logistics*, *EventOS*), viết FRS/BRD/user story bằng Markdown, dán số liệu CSV để minh họa pipeline, làm việc trên iPad kèm bàn phím, hay dùng Split View cạnh trình duyệt/call.
2. **Nhóm dự án 2–5 người** (v1.1 — vd. Hảo, Phú + PM): đồng soạn thảo user story trong buổi refinement qua Live Share; khách mời xem là chủ yếu (mặc định Viewer). Trần thiết kế 8 thành viên/phiên (relay spec §5).
3. **Giảng viên/học viên BA Bootcamp**: dùng cá nhân, có thể không đăng nhập iCloud — mọi tính năng đơn-người-dùng phải chạy đầy đủ (APP-NFR-04).

## 5. Yêu cầu chức năng (APP-FR)

### 5.1 Workspace & tài liệu

**APP-FR-01 — Tạo tài liệu tức thì.** Tạo tài liệu mới từ workspace trong **≤ 2 thao tác**, không hộp thoại chặn (một lời gọi tạo — đặt tên mặc định, đổi tên sau). Tài liệu vừa tạo **tìm thấy được ngay** trong tìm kiếm workspace.
*AC:* nhấn "+ Tài liệu mới" → tài liệu xuất hiện trong danh sách và trong kết quả FTS ngay lập tức. *Truy vết:* `DocumentStore.createDocument`, `WorkspaceViewModel`, gate M1.

**APP-FR-02 — Đa nhiệm iPadOS.** Multi-window: mỗi tài liệu mở được ở cửa sổ/scene riêng (`WindowGroup(for: Document)`); dùng cho luồng resolve xung đột 2 cửa sổ (M-01). Split View với app khác ở **đủ 3 tỷ lệ 50/50 · 33/67 · 67/33**; layout không vỡ ở cả ba (CR-D1: ma trận snapshot phải phủ cả ba tỷ lệ × 2 theme × Dynamic Type XL).
*Truy vết:* `SolApp.swift`, `SolMetrics` (pane width theo tỷ lệ), snapshot matrix M0.

**APP-FR-03 — Quy tắc trùng tên.** Trùng tên trong cùng thư mục → hậu tố **" 2", " 3", …**; **không bao giờ ghi đè im lặng**. Áp dụng thống nhất tại: tạo mới, khôi phục từ Thùng rác, di trú local→iCloud (EMMA-R-03), và bản sao xung đột lặp (APP-BR-03).
*Truy vết:* `FileNaming.collisionFreeURL` + test 4 ngữ cảnh.

**APP-FR-04 — Tìm kiếm toàn workspace (FTS).** Chỉ mục FTS5 trên title + body; **cả chỉ mục lẫn truy vấn đi qua CÙNG một phép chuẩn hóa tiếng Việt** (Phụ lục C): fold dấu, **fold đ/Đ→d** (unicode61 không làm được — PAUL-02), NFC/NFD tương đương; khớp tiền tố theo token ("duong" khớp "đường"). Phím tắt ⌘⇧F; tìm trong tài liệu là ⌘F (EMMA-R-02 — hai phím không được đổi chỗ).
*AC (= APP-AC-02):* tài liệu tìm thấy được **≤ 5 giây** kể từ trạng thái "Đã lưu cục bộ". *Truy vết:* `SearchIndex`, `VietnameseNormalizer`.

**APP-FR-05 — Command palette ⌘K.** Bảng lệnh mở bằng ⌘K, nội dung là **danh sách ĐÓNG theo Phụ lục A** — thêm/bớt lệnh đồng nghĩa sửa PRD trước (test pin cứng danh sách).
*AC:* **"100% lệnh trong Phụ lục A thực thi đúng."** Lệnh thuộc milestone chưa phát hành hiển thị **disabled, không ẩn** (G3).
*Truy vết:* `SolCommandID`, `CommandPaletteView`, `WorkspaceTests`.

### 5.2 Editor & Block Model

**APP-FR-06 — Soạn thảo Markdown.** Editor TextKit 2 với live preview; scroll-sync; 3 chế độ pane Soạn thảo / Song song / Preview (⌘1/2/3). **Cỡ tài liệu hạng 1: ~10.000 từ** — mọi ngân sách hiệu năng (APP-NFR-01) định nghĩa trên cỡ này. Block Model parse một lượt UTF-8 ra preview tree + tag gutter.
*Truy vết:* `SolEditor`, `SolBlockModel`, `PerformanceTests` (fixture > 10.000 từ).

**APP-FR-07 — Block gutter (signature).** Rail 34pt cạnh editor, **một tag mỗi dòng** phản chiếu đúng Block Model: block cấu trúc **H1 · H2 · TB · BQ · UL · DB** (DB = data block, thêm bởi CR-D2) tô accent; P/dòng trống tô muted. **Gutter là product truth** — nó phải khớp classifier của parser **100%** (AC "khớp 100%"), không phải trang trí.
*Truy vết:* `GutterAndPreview`, `BlockParser.classify`, EditorViewModel test đối chiếu gutter↔preview.

**APP-FR-08 — Toolbar định dạng.** Thanh 34pt: **B · I · H₂ · danh sách · trích dẫn · ▦ bảng** — thao tác trên văn bản thô (wrap selection / prefix dòng / chèn khung bảng 3×3), phím tắt tương ứng ở Phụ lục A (ngoài palette).
*Truy vết:* `EditorViewModel` toolbar ops + tests.

**APP-FR-09 — Data blocks (`sol-data`).** Fence ` ```sol-data type=bar|line|pie title="…" [src=data/x.csv] ` render thành chart (Swift Charts, ramp màu design.md §2.3):
- **CSV nội dòng:** dòng `nhãn,số`; dòng đầu không phải số được tha thứ **một lần** như header (`week,count`); dòng lỗi về sau là **lỗi cứng kèm số dòng 1-based**.
- **Thông báo lỗi xác định, nguyên văn** (kiểm thử verbatim — Phụ lục B): không đọc được CSV / vượt giới hạn dòng (APP-BR-02) / chưa có dữ liệu / loại chart không hỗ trợ.
- **`src=` liên kết file `data/*.csv`** trong workspace; từ chối đường dẫn thoát lên trên gốc; block có `src=` được phép body rỗng.
- **Downsample hiển thị ≤ 200 điểm** (bucket-mean, giữ nguyên điểm đầu/cuối) kèm ghi chú **"hiển thị N/M điểm"** (M-04).
- **Nhận định tự động per-type** (EMMA-06): bar/line = % thay đổi 2 kỳ cuối ("W4 tăng 47% so với W3."); pie = tỷ trọng lớn nhất ("A chiếm tỷ trọng lớn nhất — 62%."); thiếu dữ liệu/chia 0 → **ẩn dòng nhận định, không đoán**.
- **VoiceOver:** ≤ 25 điểm đọc từng giá trị; **> 25 điểm đọc summary** (số điểm, đầu–cuối, min/max, điểm cuối).
*Truy vết:* `SolDataBlocks` (parser, `DownsampleAndInsight`, `DataBlockView`).

**APP-FR-10 — File thường, không định dạng độc quyền.** Tài liệu là **file `.md` thuần mà mọi app khác mở được**; danh tính tài liệu = UUID trong sidecar (sống sót rename/move). Không nhúng metadata vào nội dung.
*Truy vết:* `Document` + sidecar trong `DocumentStore`.

### 5.3 Đồng bộ, xung đột & an toàn dữ liệu

**APP-FR-11 — Banner xung đột.** Khi resolver tạo bản sao xung đột: banner (màu warning, design.md §6) **luôn nêu đúng tên file bản sao**; hành động **"Xem bản sao"** mở bản gốc + bản sao ở 2 cửa sổ (multi-window, M-01); danh sách tài liệu refresh với bản sao được badge và nhóm sau bản gốc.
*Truy vết:* `WorkspaceViewModel` conflicts, `ConflictEvent`.

**APP-FR-12 — Journal & lịch sử phiên bản.** Pipeline lưu mỗi keystroke theo bất biến G2: **journal-before-write** (ghi journal trước, ghi file sau). Kill-app recovery: journal mới hơn file → journal thắng. **Sàn kiểm toán v1 (DAVID-01):** mỗi checkpoint version mang metadata **actor / timestamp / operation**; xung đột ghi thêm version `conflictCopy` trên bản gốc làm dấu vết. Lệnh **"Xuất snapshot"** (Phụ lục A) = named version + bản read-only.
*Truy vết:* `JournalStore`, `VersionStore`, `EditorViewModel`, `JournalAndVersionTests`.

**APP-FR-15 — Vị trí workspace & 4 trạng thái iCloud.** Bốn trạng thái được mô hình hóa đầy đủ (APP-AC-09): **khả dụng** (workspace trên container) · **chưa đăng nhập iCloud** · **iCloud Drive tắt cho Sol** · **hết dung lượng** (chỉ phát hiện được từ lỗi ghi — không pre-flight). Ba trạng thái sau → **workspace cục bộ đầy đủ tính năng** (APP-NFR-04) kèm **thông báo trung thực, riêng cho từng trạng thái** (nguyên văn Phụ lục B). Khi iCloud khả dụng trở lại: **đề nghị di trú** local→iCloud — không tự động, **không bao giờ ghi đè** (EMMA-R-03): trùng tên nhận hậu tố APP-FR-03 (đây không phải xung đột sync nên không dùng tên conflicted copy); copy-then-delete để crash giữa chừng không mất nguồn (G2).
*Truy vết:* `WorkspaceLocation`, `ICloudStatus`, `UbiquityProviding` (injectable đủ 4 trạng thái).

**APP-FR-16 — Settings.** Đủ 6 mục, mỗi dòng AC có test riêng:
1. **Theme** (Theo hệ thống/Sáng/Tối) — hiệu lực **NGAY trên mọi màn hình, không restart**.
2. **Ngôn ngữ UI** (vi/en) — được phép cần restart **nhưng PHẢI thông báo** ngay khi chọn.
3. **Phím tắt** — render từ **chính nguồn danh sách đóng** (SolCommandID + NonPaletteShortcuts, Phụ lục A); lệnh milestone sau ghi rõ "từ M2+".
4. **Thùng rác** — lối vào APP-FR-17.
5. **Telemetry** — toggle Lớp 1 (hiệu lực **từ sự kiện kế tiếp**) + nút xóa toàn bộ log trên máy; footer nêu đúng hợp đồng 2 lớp (APP-NFR-08).
6. **Giới thiệu** — phiên bản build, font (Be Vietnam Pro · Inter — giấy phép OFL), hệ thiết kế (ADR-D07/D08).
*Truy vết:* `SettingsView`, `SettingsStore`, `SettingsTests` (một test mỗi dòng AC).

**APP-FR-17 — Thùng rác.** Xóa tài liệu → vào Thùng rác, **khôi phục được trong 30 ngày**; khôi phục về vị trí cũ (trùng tên → hậu tố APP-FR-03). **Xóa vĩnh viễn luôn qua hộp xác nhận** nêu rõ purge cascade (APP-BR-04). **Tự dọn ở lần mở app đầu tiên sau khi đủ 30 ngày** (best-effort). Bản sao xung đột nằm **nhóm riêng có badge** (M-01) để dọn chủ động sau khi resolve.
*Truy vết:* `TrashView`, `DocumentStore` trash lifecycle, gate M1.

### 5.4 Live Share (phát hành v1.1 — HR-2)

**APP-FR-13 — Phiên cộng tác thời gian thực.** Đồng soạn thảo qua CRDT text (RGA + causal buffering) trên relay (HR-5: Cloudflare Durable Objects; spec riêng đã duyệt).
*AC #1:* **"3 người gõ đồng thời hội tụ về cùng nội dung"** (fuzz 3-actor trong CI).
**State machine 8 sự kiện** — bảng này là hợp đồng hành vi; mỗi hàng có test Lớp 1:

| # | Sự kiện | Hành vi |
|---|---|---|
| 1 | Owner tạo phiên | Phiên ACTIVE, owner giữ token duy nhất (không owner-transfer ở v1.1) |
| 2 | Guest join qua link | Vào roster, **mặc định Viewer** (APP-BR-01), broadcast roster |
| 3 | Guest rời / mất mạng | `member_left`; phiên tiếp tục |
| 4 | Owner mất mạng | Phiên **SUSPENDED**; guest tiếp tục XEM; thao tác ghi của guest-editor **tạm giữ local** |
| 5 | Owner trở lại ≤ 15′ | ACTIVE trở lại; **held ops replay** — không mất keystroke nào (G2) |
| 6 | Quá 15′ (timer chạy **trên relay** — EMMA-R-01) | Tự END theo quy tắc snapshot: client lưu snapshot local read-only **chứa cả thao tác tạm giữ** (G2) |
| 7 | Owner end / thu hồi toàn bộ | END, ngắt tất cả, snapshot như trên; end ≠ revoke-link (APP-FR-14) |
| 8 | Mở link sau END | "Phiên đã kết thúc" (relay trả 410) |

Độ trễ hiển thị **< 250ms** với network profile chuẩn APP-NFR-01 (RTT ≤ 50ms, ≥ 10Mbps, loss 0%). **Mất relay → app degrade về local + iCloud, không mất dữ liệu.** Nghiệm thu 2 lớp theo ADR-A03: Lớp 1 = `MockRelayHub` (executable reference của SPEC-RELAY §4, clock-inject cho timer 15′); Lớp 2 = relay staging (`CloudflareCollabTransport`).
*Truy vết:* `SolCollab` (TextCRDT, CollabSession, MockRelayHub), `SessionStateMachineTests`.

**APP-FR-14 — Chia sẻ & quyền.** Share sheet: link phiên + vai trò từng thành viên (Editor/Viewer) + ghi chú "Quyền mặc định: Viewer" + **cảnh báo APP-BR-06 nguyên văn**. **Thu hồi link ≠ kết thúc phiên** (PAUL-09): revoke chỉ chặn join mới, thành viên đang trong phiên không bị ngắt; end mới ngắt tất cả theo quy tắc snapshot. Đổi vai trò có hiệu lực server-side ngay (không chờ client thiện chí).
*Truy vết:* `CollabUI` share sheet, relay spec §4.1.

## 6. Quy tắc nghiệp vụ (APP-BR)

| Mã | Quy tắc |
|---|---|
| **APP-BR-01** | Link chia sẻ **mặc định Viewer**. Guest join luôn nhận role viewer; nâng quyền là hành động chủ động của owner. Cưỡng chế **ở relay**, không phải ở UI (APP-AC-06). |
| **APP-BR-02** | Giới hạn tài nguyên, báo lỗi rõ kèm hướng xử lý: file `.md` **≤ 10 MB** ("File vượt giới hạn 10 MB (APP-BR-02). Hãy tách nhỏ tài liệu.") · CSV data block **≤ 10.000 dòng** (thông điệp nguyên văn Phụ lục B). Giới hạn cũng chốt cỡ snapshot chunking của relay. |
| **APP-BR-03** | Tên bản sao xung đột **nguyên văn**: `<tên> (conflicted copy <người> <yyyy-MM-dd>).md` — ngày ISO, từ khóa tiếng Anh **bất kể locale** (cross-locale để hai máy khác ngôn ngữ sinh cùng tên); lặp xung đột → thêm hậu tố số APP-FR-03. |
| **APP-BR-04** | **Purge cascade đủ 4 nơi**, không sót: nội dung file (+ sidecar) · journal · toàn bộ version history · chỉ mục tìm kiếm. Xóa vĩnh viễn luôn qua hộp xác nhận nêu đúng 4 nơi; tự dọn sau 30 ngày ở lần mở app (APP-FR-17). Kiểm chứng được: sau purge, tài liệu không reachable qua bất kỳ store nào (APP-AC-08). |
| **APP-BR-05** | **Không hard-code màu/chữ/spacing** — chỉ dùng token `SolColor`/`SolFont`/`Sol.*` (ADR-M0-01: token là code constants, không .xcassets). |
| **APP-BR-06** | Share sheet Live Share phải cảnh báo nguyên văn: *"Nội dung tài liệu sẽ được gửi qua máy chủ relay đặt tại Singapore."* (gộp quyết định region HR-5 §10.1 và HR-3). Đối ứng: relay phải tối thiểu hóa dữ liệu thấy/giữ (relay spec §6 — delta là bytes mờ, chỉ transit + ring buffer, không durable storage). |

## 7. Yêu cầu phi chức năng (APP-NFR)

| Mã | Yêu cầu |
|---|---|
| **APP-NFR-01** | **Hiệu năng trong mạch gõ:** keystroke→preview **p95 ≤ 50ms** (trong đó phần parser ≤ 25ms), đo trên **bản Release, iPad gen 10**, tài liệu hạng 1 ~10k từ (APP-FR-06) — đo chính thức ở M6 perf suite. CI giữ **tripwire hồi quy** (Debug, estimator min-of-N vì runner chia sẻ có scheduler stall; **không được nâng số tripwire** — chỉ tối ưu code hoặc leo thang sang incremental splicing). Network profile chuẩn cho chỉ tiêu collab: RTT ≤ 50ms, ≥ 10Mbps, loss 0% → hiển thị < 250ms (APP-FR-13). |
| **APP-NFR-02** | **Mọi đường phá hủy có đường khôi phục:** xóa → Thùng rác 30 ngày; sửa → journal + versions; xung đột → cả hai bản được giữ; xóa vĩnh viễn → qua xác nhận; di trú → copy-then-delete. Không tồn tại thao tác một-bước mất dữ liệu. |
| **APP-NFR-03** | **Tối thiểu hóa dữ liệu rời máy.** V1 đơn-người-dùng: không có gì rời máy ngoài iCloud của chính người dùng. V1.1: relay chỉ thấy metadata phiên + bytes mờ trong transit (relay spec §6); linkKey nằm trong fragment URL nên không rơi vào server logs. |
| **APP-NFR-04** | **Không cần tài khoản iCloud:** toàn bộ tính năng đơn-người-dùng chạy đầy đủ trên workspace cục bộ — local workspace là workspace thật, không phải stub. |
| **APP-NFR-05** ② | **Truy cập được (a11y):** VoiceOver có nghĩa trên mọi màn hình (chart theo quy tắc ≤ 25 điểm của APP-FR-09); Dynamic Type tới XL không vỡ layout (nằm trong ma trận snapshot); tôn trọng Reduce Motion (tắt mọi vòng lặp — design.md §7); đạt các cặp contrast design.md §2.5. Audit đầy đủ theo **Phụ lục D** là gate M6. |
| **APP-NFR-06** | **Kiến trúc thay được:** đồng bộ qua `SyncEngine` protocol (iCloud hôm nay, backend riêng sau này không đập app); collab qua `CollabTransport` (mock ↔ Cloudflare đổi được không đụng client); parser/block model độc lập UI. |
| **APP-NFR-07** | **Glyph tiếng Việt đầy đủ:** font UI phủ **134/134** ký tự tiếng Việt (gồm ơ/ư U+01A0–01B0 và toàn dải U+1EA0–1EFF — lý do ADR-D08 thay Poppins bằng Be Vietnam Pro); snapshot test khẳng định render đúng cả dạng precomposed lẫn combining ở mỗi lần đổi font (Phụ lục C). |
| **APP-NFR-08** | **Telemetry 2 lớp, cưỡng chế bằng type system:** **Lớp 1** (vận hành, mặc định BẬT, tắt được trong Settings, hiệu lực từ sự kiện kế tiếp) = tập sự kiện ĐÓNG chỉ chứa số/mã lỗi/thời lượng: `sync_completed(durationMs, errorCode?)` · `journal_recovered` · `conflict_resolved` · `crash_marker_found` · `weekly_conflict_aggregate(conflictedDocs, syncedDocs)`. **Lớp 2 — KHÔNG BAO GIỜ thu:** nội dung tài liệu, tên file, từ khóa tìm kiếm, dữ liệu CSV — **schema không tồn tại field chở được nội dung**; ràng buộc nằm trong cấu trúc sự kiện, không phải lời hứa chính sách. V1 log chỉ nằm trên máy (append-only, xóa được); backend upload đến GĐ sau kế thừa đúng hợp đồng này. |

## 8. Nghiệm thu vàng (APP-AC)

Danh sách kiểm tra cấp phát hành — mỗi mục phải chứng minh được bằng test hoặc kịch bản thiết bị thật:

| Mã | Nội dung | Lớp nghiệm thu (ADR-A03) |
|---|---|---|
| APP-AC-01 ③ | *(tái lập — nhiều khả năng: luồng tạo/mở tài liệu ≤ 2 thao tác của APP-FR-01)* | Lớp 1 |
| APP-AC-02 | Tài liệu tìm thấy được qua FTS **≤ 5s** kể từ "Đã lưu cục bộ" | Lớp 1 |
| APP-AC-03 | **Kịch bản vàng e2e iCloud 2 thiết bị:** sửa cùng tài liệu trên 2 iPad, một máy offline → cả hai phiên bản được bảo toàn, bản sao xung đột đặt tên đúng APP-BR-03, banner APP-FR-11 hiện đúng | **Lớp 2 — thiết bị thật (gate M4/M6, chưa đóng)** |
| APP-AC-04 ③ | *(tái lập — nhiều khả năng: gutter khớp classifier 100% / ngân sách keystroke p95 của APP-NFR-01 đo Release)* | Lớp 2 |
| APP-AC-05 | **Chip sync trung thực:** chỉ hiển thị trạng thái xác minh được; không có backing iCloud thì mọi thứ dừng ở "Đã lưu cục bộ" (M-02: pha M1–M3 chip luôn là "Đã lưu cục bộ") | Lớp 1 |
| APP-AC-06 | **Viewer bị chặn ghi Ở RELAY:** frame `update` từ role viewer bị từ chối server-side với `FORBIDDEN_ROLE` — không phụ thuộc UI | Lớp 1 (mock) + tuần 9 (staging) |
| APP-AC-07 ③ | *(tái lập — nhiều khả năng: khôi phục từ Thùng rác về đúng vị trí với quy tắc hậu tố)* | Lớp 1 |
| APP-AC-08 | **Purge cascade kiểm chứng được:** sau xóa vĩnh viễn, tài liệu biến mất khỏi đủ 4 nơi (nội dung, journal, versions, chỉ mục) — không reachable | Lớp 1 |
| APP-AC-09 | **Đủ 4 trạng thái iCloud có hành vi đặc tả** + di trú local→iCloud không ghi đè, trùng tên nhận hậu tố | Lớp 1 (provider inject) |

## 9. Ràng buộc thiết kế & thương hiệu

Toàn bộ đặc tả thị giác nằm ở [`design.md`](design.md) (nguồn: Sol Design & Brand Guideline chính thức — ADR-D07 thay thế spec màu xanh của PRD §3.1 cũ). Ràng buộc mức PRD:

- Token màu/chữ/spacing là **luật** (APP-BR-05); heading **Be Vietnam Pro**, body **Inter** (ADR-D08).
- Bảng trong preview: header nền Burnt Core `#8F3408` chữ cream; H2 preview có thanh accent trái 3pt.
- Chart dùng đúng ramp §2.3; không dùng accent cam đồng thời cho UI-selected và series trong cùng view.
- Presence palette §2.4 (HR-6): self = orange.core, peer-1 slate, peer-2 violet, peer-3 teal.
- Trang trí sanctioned tối đa 1 loại/màn hình, không bao giờ sau chữ (dot grid cho empty state, orbit rings, radial glow dark-mode, hatch loading).
- Motion: chỉ 3 vòng lặp được phép (LIVE pulse, sync dot, cursor blink); tôn trọng Reduce Motion.

## 10. Sổ quyết định PO (HR) — 6/6 đã chốt

| Mã | Quyết định |
|---|---|
| HR-1 | Heading typeface: **Be Vietnam Pro** (nguồn gốc CR-D3/ADR-D08; Brand Guideline PDF sẽ amend phía marketing) |
| HR-2 | **Live Share = v1.1**: SolCollab code xong, giữ NGOÀI dependency của app target v1 (comment đánh dấu trong `project.yml`) |
| HR-3 | **Confidential:** v1 không có label; thay bằng cảnh báo relay + region SIN trong share sheet (APP-BR-06) |
| HR-4 | Sàn nền tảng: **iPadOS 17 / iPad gen 10** (thiết bị tham chiếu cho mọi chỉ tiêu perf) |
| HR-5 | Relay = **Cloudflare Durable Objects** (spec v1.0 đã duyệt; region SIN cho beta) |
| HR-6 | Duyệt **presence palette §2.4** + bộ warm neutrals dẫn xuất §2.1 làm token chính thức |

## 11. Change Requests đã áp (→ v1.2.1)

| CR | Nội dung | Chạm vào |
|---|---|---|
| CR-D1 | Ma trận snapshot phải phủ **cả 3 tỷ lệ Split View** | APP-FR-02, design.md §9 |
| CR-D2 | Tag gutter thêm **DB** (data block) vào nhóm cấu trúc | APP-FR-07 |
| CR-D3 | **Be Vietnam Pro thay Poppins** (bằng chứng cmap: Poppins 46/134 glyph) | APP-NFR-07, design.md ADR-D08 |
| CR-M1 | Thêm **S6 Thùng rác** + đặc tả đủ **4 trạng thái iCloud** | APP-FR-15/17, APP-BR-04, mockups v3.1+ |

## 12. Phán quyết KG-BA Council được viện dẫn trong đặc tả

| Mã | Phán quyết → hệ quả trong PRD |
|---|---|
| PAUL-02 | SQLite `unicode61 remove_diacritics` **không fold đ/Đ** (U+0111/U+0110 là chữ độc lập) → tự chuẩn hóa theo Phụ lục C (APP-FR-04) |
| PAUL-05 | Relay không phải "dumb pipe", spec phải có sớm → SPEC-RELAY v0.1→v1.0; MockRelayHub = executable reference |
| PAUL-09 | **Thu hồi link ≠ kết thúc phiên** — hai hành vi tách biệt (APP-FR-14) |
| EMMA-06 | Nhận định chart phải **per-type**, không một câu chung (APP-FR-09) |
| EMMA-R-01 | Timer SUSPENDED→END 15′ chạy **trên relay**, không phải client (APP-FR-13) |
| EMMA-R-02 | Không trùng phím tắt trong hợp nhất palette + ngoài-palette; ⌘F = trong tài liệu, ⌘⇧F = workspace (Phụ lục A) |
| EMMA-R-03 | Di trú local→iCloud **không bao giờ ghi đè** — hậu tố APP-FR-03, không phải tên conflicted copy (APP-FR-15) |
| DAVID-01 | Sàn kiểm toán version: **actor/timestamp/operation** trên mỗi checkpoint (APP-FR-12) |
| M-01 | Bản sao xung đột: badge + nhóm sau bản gốc + vẫn được index (G2); resolve qua 2 cửa sổ (APP-FR-11, APP-FR-17) |
| M-02 | Chip sync theo pha: M1–M3 luôn "Đã lưu cục bộ" — không claim sync khi chưa có SyncEngine backing (APP-AC-05) |
| M-04 | Chart downsample ≤ 200 điểm + ghi chú N/M (APP-FR-09) |

**ADR viện dẫn:** ADR-A01 rev.2 (mã APP-/PLT-) · ADR-A02 rev.2 (resolver không-merge, ranh giới CRDT) · ADR-A03 (nghiệm thu 2 lớp: Lớp 1 mô phỏng được trong CI, Lớp 2 thiết bị thật/staging; "mọi phiên bản phát hiện được đều được bảo toàn") · ADR-D07/D08 (design.md) · ADR-M0-01 (token là code constants).

## 13. Milestones & gates

| Milestone | Phạm vi PRD | Gate |
|---|---|---|
| M0 — Design System | §9, APP-BR-05, APP-NFR-07 | Token + components + contrast CI; snapshot baseline (Mac) |
| M1 — Workspace + Store | APP-FR-01/03/04/05/15/17, APP-BR-02/04, APP-AC-02/08/09 | CI xanh (đã đạt) |
| M2 — Editor + Block Model | APP-FR-06/07/08/12, APP-NFR-01 tripwire | CI xanh (đã đạt) |
| M3 — Data Blocks | APP-FR-09, APP-BR-02 | CI xanh (đã đạt) |
| M4 — Sync + Conflict | APP-FR-02/11, APP-BR-03, APP-AC-03/05 | Lớp 1 xanh; **Lớp 2 mở: NSFileVersion monitor + e2e 2 thiết bị** |
| M5 — Live Share (v1.1) | APP-FR-13/14, APP-BR-01/06, APP-AC-06 | Lớp 1 xanh; còn `CloudflareCollabTransport` khi relay staging (tuần 10) |
| M6 — Hoàn thiện | APP-NFR-01 đo Release, APP-NFR-05 + Phụ lục D | A11y audit, perf thiết bị thật, TestFlight |

---

## Phụ lục A — Danh sách lệnh & phím tắt v1 (ĐÓNG)

Danh sách này là **một phần của tiêu chí nghiệm thu APP-FR-05**: thêm/bớt/đổi phím = sửa PRD trước, sửa code sau (test pin cứng cả hai bảng; không phím nào được trùng nhau trong hợp nhất hai bảng — EMMA-R-02).

**A.1 — Lệnh trong command palette (⌘K):**

| Lệnh | Phím tắt | Khả dụng |
|---|---|---|
| Chèn bảng | ⌘⇧T | từ M2 |
| Chèn sol-data block | ⌘⇧D | từ M3 |
| Xuất snapshot | — | từ M2 |
| Tài liệu mới | ⌘N | M1 |
| Chuyển chế độ pane | ⌘1/2/3 | từ M2 |
| Tìm trong tài liệu | ⌘F | từ M2 |
| Tìm trong workspace | ⌘⇧F | M1 |
| Mở Thùng rác | — | M1 |

Lệnh chưa tới milestone hiển thị **disabled, không ẩn** (G3).

**A.2 — Phím tắt ngoài palette:**

| Hành động | Phím |
|---|---|
| In đậm | ⌘B |
| In nghiêng | ⌘I |
| Heading 2 | ⌘⇧H |
| Danh sách | ⌘⇧L |
| Trích dẫn | ⌘⇧Q |
| Đóng overlay | Esc |
| Đóng cửa sổ | ⌘W |
| Mở Settings | ⌘, |

## Phụ lục B ③ — Thông điệp người dùng nguyên văn (kiểm thử verbatim)

**B.1 — Lỗi giới hạn & CSV (APP-FR-09 / APP-BR-02):**

- `File vượt giới hạn 10 MB (APP-BR-02). Hãy tách nhỏ tài liệu.`
- `Không đọc được CSV — cần dạng \`W1,120\` (dòng lỗi đầu tiên: <n>: "<nội dung>")`
- `CSV vượt giới hạn 10000 dòng (APP-BR-02). Hãy tách nhỏ dữ liệu hoặc liên kết file đã tổng hợp.`
- `Chưa có dữ liệu — thêm các dòng dạng \`W1,120\` vào block.`
- `Loại chart "<t>" không hỗ trợ — dùng bar, line hoặc pie.`

**B.2 — Thông báo 4 trạng thái iCloud (APP-FR-15):**

- *Khả dụng:* chip "iCloud khả dụng — workspace trên container" (không banner).
- *Chưa đăng nhập:* "**Chưa đăng nhập iCloud** — đang dùng workspace cục bộ, đầy đủ tính năng đơn-người-dùng (APP-NFR-04). Bật iCloud để đồng bộ."
- *Drive tắt cho Sol:* "**iCloud Drive đang tắt cho Sol** — đang dùng workspace cục bộ. Bật trong Settings hệ thống để đồng bộ."
- *Hết dung lượng:* "**iCloud hết dung lượng** — thay đổi được giữ cục bộ, sẽ đồng bộ khi có chỗ. Khi khả dụng trở lại: đề nghị **di trú** (không tự động, không ghi đè — trùng tên nhận hậu tố, APP-FR-15)."

**B.3 — Cảnh báo share sheet (APP-BR-06):** "Link mới mở với quyền Viewer (APP-BR-01). Nội dung tài liệu sẽ được gửi qua máy chủ relay đặt tại Singapore."

## Phụ lục C — Tiếng Việt: tìm kiếm & typography

**C.1 — Chuẩn hóa tìm kiếm (APP-FR-04).** Cả chỉ mục lẫn truy vấn đi qua CÙNG phép fold: (1) decompose canonical (NFC/NFD hội tụ) + lowercase; (2) bỏ combining marks U+0300–U+036F (dấu thanh/mũ/breve — ư/ơ decompose thành u/o + U+031B nên được xử lý ở bước này); (3) **fold đ (U+0111) → d** thủ công — chữ tiếng Việt duy nhất không decompose thành base+mark, đúng lỗ hổng `unicode61` mà PAUL-02 chỉ ra; (4) recompose NFC. Truy vấn tự do → mỗi token thành `"token"*` (khớp tiền tố).

**C.2 — Độ phủ glyph (APP-NFR-07).** Bộ 134 ký tự tiếng Việt (gồm Ơ/ơ Ư/ư U+01A0–01B0 và toàn dải U+1EA0–1EFF) phải được font UI phủ 100%: **Be Vietnam Pro 134/134 · Inter 134/134** (audit cmap 02/08/2026 — ADR-D08; Poppins chỉ 46/134 nên bị loại). Snapshot test khẳng định render đúng cả chuỗi precomposed lẫn combining ở mỗi lần cập nhật font.

## Phụ lục D — Danh mục audit truy cập được (gate M6) ②

1. **VoiceOver:** mọi màn hình đọc có nghĩa theo thứ tự hợp lý; chart tuân quy tắc APP-FR-09 (≤ 25 điểm đọc từng giá trị; > 25 đọc summary số-điểm/đầu-cuối/min/max/điểm-cuối); nút icon có label.
2. **Dynamic Type:** tới XL không vỡ layout, không cắt chữ (nằm trong ma trận snapshot M0 cùng 2 theme × 3 tỷ lệ Split View).
3. **Bàn phím cứng:** đủ phím tắt Phụ lục A; focus-visible rõ (outline sunrise); Esc đóng mọi overlay.
4. **Reduce Motion:** tắt LIVE pulse, sync dot, cursor blink — crossfade thay vì move (design.md §7).
5. **Contrast:** đạt các cặp design.md §2.5 (assert trong CI); không đặt accent/logo trên nền tương phản thấp.
6. **Ngôn ngữ:** VoiceOver đọc đúng tiếng Việt có dấu (liên quan APP-NFR-07).

---

## 14. Ghi chú tái lập (provenance)

Bản này tái lập từ **dấu vết yêu cầu trong repo** (code, test, README, design.md, relay spec, mockups) — phần lớn nội dung là **nguyên văn hoặc suy ra trực tiếp** từ các nguồn đó và có ghi *Truy vết* tại chỗ. Ba loại đánh dấu:

- **①** Cách phát biểu mục tiêu **G1** không còn dấu vết trong repo (G2/G3/G4 có); nội dung "tốc độ trong mạch suy nghĩ" suy từ vai trò của APP-NFR-01. Đối chiếu bản gốc khi truy cập được `E:\Documents`.
- **②** **APP-NFR-05** không xuất hiện trong repo (NFR-01→04, 06→08 đều có); gán cho a11y vì Phụ lục D tồn tại mà chưa có NFR neo. Danh mục Phụ lục D tổng hợp từ các quy tắc a11y rải trong repo, có thể thiếu mục so với bản gốc.
- **③** **APP-AC-01/04/07** không còn dấu vết (AC-02/03/05/06/08/09 có) — giữ số để không đánh số lại, kèm suy đoán trong ngoặc. Tiêu đề "Phụ lục B" là tái lập (repo chỉ tham chiếu Phụ lục A/C/D); nội dung B là các chuỗi được test verbatim.

Khi đối chiếu được bản `E:\Documents`, cập nhật các mục ①②③ bằng commit riêng và xóa ghi chú tương ứng.
