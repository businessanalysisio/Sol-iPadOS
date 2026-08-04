# Spec kỹ thuật — Sol Live Share Relay Service

**Mã tài liệu:** SPEC-RELAY · **Phiên bản:** v1.0 — ✅ **HR-5 ĐÃ CHỐT 04/08/2026 (PO phê duyệt theo đề xuất)** · trước hạn tuần 8
**Phục vụ:** PRD-APP-IPAD v1.2 — APP-FR-13/14 (phát hành v1.1), APP-BR-01/06, APP-AC-06, ADR-A02 rev.2
**Quyết định:** Cloudflare Workers + Durable Objects · A3 part-time tuần 8–10 · capability link + HMAC token. Các mục §10 chốt theo đề xuất (chi tiết cuối tài liệu); tiểu mục duy nhất còn treo: domain share link (không chặn build — staging dùng `*.workers.dev`).

---

## 0. Tóm tắt cho người quyết định (HR-5)

HR-5 hỏi 3 câu: **ai xây · hosting ở đâu · auth mô hình gì.** Đề xuất của spec này:

| Câu hỏi | Đề xuất | Lý do ngắn |
|---|---|---|
| Hosting/kiến trúc | **Cloudflare Workers + Durable Objects** (1 DO = 1 phiên) | Session state machine + timer 15 phút map thẳng vào DO alarms; WebSocket hibernation; không có server phải vận hành; chi phí ~0 ở quy mô hiện tại |
| Ai xây | **A3 backend part-time (từ tuần 8)** — ước 2 tuần build + 1 tuần test matrix | Phạm vi đã thu hẹp nhờ relay content-agnostic (§4); template DO + WS có sẵn |
| Auth | **Capability link + HMAC session token** (không tài khoản người dùng ở v1.1) | Khớp APP-BR-01 (link mặc định Viewer); không phải dựng identity system trước khi có team workspace |

Phương án so sánh và lý do loại: §8. Rủi ro chính và câu hỏi mở cho PO: §9–10.

---

## 1. Phạm vi

**Relay là:** dịch vụ trung chuyển realtime cho phiên Live Share — quản lý vòng đời phiên (state machine APP-FR-13), cưỡng chế quyền Editor/Viewer **ở tầng server** (APP-AC-06), chuyển tiếp CRDT delta + presence giữa các peer, đo độ trễ.

**Relay KHÔNG là:**
- Không phải nơi lưu tài liệu — tài liệu sống trong iCloud container của owner; relay chỉ giữ trạng thái phiên và buffer chuyển tiếp trong thời gian phiên sống.
- Không đọc nội dung — CRDT payload là **bytes mờ** (opaque) với relay (§6).
- Không phải sync backend thay iCloud — mất relay thì app degrade về local + iCloud (APP-FR-13), không mất dữ liệu.
- Chưa phải team workspace (PLT-FR-13 đầy đủ) — đó là GĐ3, kiến trúc này không được cản đường nó nhưng không xây trước.

## 2. Ràng buộc kế thừa từ PRD (bất khả xâm phạm)

1. **State machine 8 sự kiện** của APP-FR-13 là hợp đồng hành vi; **timer SUSPENDED→END 15 phút chạy trên relay** (không phải client — EMMA-R-01).
2. **Viewer bị chặn ghi ở relay**: frame `update` từ connection mang role Viewer bị từ chối server-side, không phụ thuộc UI (APP-AC-06).
3. **Thu hồi link ≠ kết thúc phiên**: revoke chỉ chặn join mới; end ngắt tất cả theo quy tắc snapshot (APP-FR-14/PAUL-09).
4. **Ranh giới CRDT**: chỉ thay đổi đi qua relay được merge CRDT; xung đột kênh iCloud vẫn tạo conflicted copy kể cả khi phiên đang chạy (ADR-A02 rev.2).
5. **APP-BR-06**: share sheet cảnh báo "nội dung sẽ được gửi qua máy chủ relay" — nghĩa là relay phải tối thiểu hóa cái nó thấy và giữ (§6).
6. Độ trễ hiển thị **< 250ms** với network profile chuẩn APP-NFR-01 (RTT ≤ 50ms, ≥ 10Mbps, loss 0%).

## 3. Kiến trúc đề xuất

```
iPad A (owner) ──WSS──┐
iPad B (editor) ─WSS──┤──> Cloudflare Worker (auth, routing) ──> Durable Object "session:<id>"
iPad C (viewer) ─WSS──┘         │                                  ├─ state machine + roles (in-DO storage)
                                └─ REST: POST /sessions            ├─ alarm: 15-min suspend timer
                                        POST /sessions/:id/revoke  └─ WS fan-out (hibernation API)
```

- **1 Durable Object = 1 phiên**: cô lập tự nhiên, tuần tự hóa message trong phiên (không race), state machine + role table nằm trong DO storage, hủy khi phiên END.
- **Worker** làm cửa: validate token, rate limit, mint token, route tới DO.
- **WebSocket Hibernation API**: giữ hàng nghìn kết nối idle không tốn compute; phù hợp phiên họp kéo dài.
- **DO alarm** = timer 15 phút của trạng thái SUSPENDED — đúng yêu cầu "timer chạy trên relay".

## 4. Giao thức

### 4.1 Vòng đời phiên (REST, JSON)

| Endpoint | Ai gọi | Hành vi |
|---|---|---|
| `POST /v1/sessions` | Owner (app) | Tạo phiên: body {docTitleHash, ownerName}. Trả {sessionID, ownerToken, shareURL: sol.io/s/<id>#<linkKey>} |
| `POST /v1/sessions/:id/join` | Guest (app) | Body {linkKey, displayName}. Trả {memberToken(role=viewer), wsURL} — **mặc định Viewer** (APP-BR-01) |
| `POST /v1/sessions/:id/roles` | Owner | {memberID, role: editor\|viewer} — hiệu lực ngay trên connection đang mở |
| `POST /v1/sessions/:id/revoke-link` | Owner | Vô hiệu linkKey — **chỉ chặn join mới**, người trong phiên không bị ảnh hưởng |
| `POST /v1/sessions/:id/end` | Owner | END: broadcast `session_ended`, đóng mọi WS, xóa DO state |

### 4.2 WebSocket frames (envelope: `{t, seq, from, payload}`)

| Frame `t` | Chiều | Ghi chú |
|---|---|---|
| `hello` | C→S | Kèm memberToken; server trả `welcome` {members, state, sinceSeq} |
| `update` | C→S→các C khác | **CRDT delta, bytes mờ** (base64/binary). Server KHÔNG giải mã. **Từ chối nếu role=viewer → `err{code:FORBIDDEN_ROLE}`** (APP-AC-06) |
| `snapshot_req` / `snapshot` | C↔S | Guest mới join xin snapshot; relay yêu cầu owner (hoặc editor bất kỳ) gửi, chuyển tiếp — relay không giữ snapshot sau khi giao |
| `presence` | C→S→C | Con trỏ/selection (offset + màu §2.4); cho phép cả Viewer |
| `role_changed` / `member_joined` / `member_left` | S→C | Roster + quyền realtime |
| `suspended` / `resumed` | S→C | Owner mất mạng → SUSPENDED (guest tiếp tục XEM, thao tác ghi tạm giữ local theo APP-FR-13); owner quay lại ≤15' → `resumed`, guest-editor replay thao tác tạm giữ qua `update` thường |
| `session_ended` | S→C | Kèm reason: owner_end \| timeout \| revoked_all; client lưu snapshot local read-only (G2) |
| `ping`/`pong` | C↔S | Đo độ trễ hiển thị; client gửi mỗi 5s |

**Thứ tự & replay:** `seq` tăng đơn điệu do DO cấp; client giữ `sinceSeq` để nhận lại phần thiếu sau reconnect ngắn (buffer vòng 512 frame trong DO, chỉ trong thời gian phiên sống). CRDT tự hội tụ nên mất frame ngoài buffer không phá đúng đắn — chỉ tốn một lần snapshot lại.

### 4.3 Ánh xạ state machine PRD → relay

| Sự kiện PRD (APP-FR-13) | Cơ chế relay |
|---|---|
| Owner tạo phiên | POST /sessions → DO khởi tạo ACTIVE |
| Guest join | join + hello; roster broadcast |
| Guest rời/mất mạng | WS close → `member_left`; phiên tiếp tục |
| Owner mất mạng | WS owner close → state=SUSPENDED, **DO alarm đặt +15 phút**, broadcast `suspended` |
| Owner trở lại ≤ 15' | hello(ownerToken) → hủy alarm, state=ACTIVE, broadcast `resumed` |
| Tự END (timeout) | Alarm nổ → như owner-end: broadcast `session_ended{timeout}`, đóng WS, xóa state |
| Owner end / thu hồi | §4.1 — end ≠ revoke-link, hai endpoint riêng |
| Mở link sau END | join trả 410 GONE → app hiện "Phiên đã kết thúc" |

## 5. Auth — capability link + HMAC token

- **Không có tài khoản người dùng ở v1.1** (danh tính = displayName tự khai, đúng mức phiên cộng tác ad-hoc; identity thật đến cùng team workspace GĐ3).
- `linkKey` trong fragment (`#`) của share URL — **không rơi vào server logs** (fragment không gửi qua HTTP).
- Token = HMAC-signed (Worker secret) chứa `{sessionID, memberID, role, exp: 24h}`; role đổi → token mới đẩy qua `role_changed`, connection cũ cập nhật server-side ngay (không chờ client thiện chí).
- Owner token chỉ mint lúc tạo phiên; **owner offline không ủy quyền được** — khớp quyết định state machine (không owner-transfer ở v1.1).
- Chống abuse: rate limit theo IP trên POST /sessions và join; max 8 member/phiên (persona nhóm 2–5, dư biên); max frame 64KB, snapshot chunking (tài liệu ≤10MB theo APP-BR-02 → ~160 chunk, chỉ lúc join).

## 6. Dữ liệu & riêng tư (G4, APP-BR-06, APP-NFR-03)

| Relay thấy/giữ | Thời gian sống | Ghi chú |
|---|---|---|
| Session metadata (id, state, roster: displayName + role) | Đến khi END | Trong DO storage |
| CRDT delta / snapshot | **Chỉ trong transit + ring buffer 512 frame** | Bytes mờ, không giải mã, không ghi durable storage |
| docTitleHash (SHA-256) | Đến khi END | Để app đối chiếu phiên↔file; **không gửi tên file thật** |
| Log vận hành | 30 ngày | CHỈ số đếm/mã lỗi/duration — cùng kỷ luật schema TelemetryEvent (không nội dung, không displayName trong log) |

- TLS bắt buộc (WSS); không cookie, không tracking.
- **Region:** Durable Object pin khu vực APAC (SIN gần VN nhất — Cloudflare chưa có DO region VN). Ghi nhận cho PO: dữ liệu phiên transit qua Singapore; nếu ràng buộc chủ quyền dữ liệu xuất hiện (khách enterprise GĐ3+) → điểm chuyển sang self-host (§8B) đã chừa sẵn nhờ giao thức độc lập hạ tầng.
- E2E encryption (client mã hóa delta, relay mù hoàn toàn): **không làm ở v1.1** (đội 1 backend part-time; key exchange không có identity system là hứa suông) — ghi thành open item §10, APP-BR-06 cảnh báo người dùng đúng như PRD.

## 7. NFR

| Chỉ tiêu | Mức | Đo/kiểm |
|---|---|---|
| Độ trễ relay (frame in→fan-out) | p95 < 30ms trong region | Đủ để tổng end-to-end < 250ms với RTT ≤ 50ms×2 + xử lý client |
| Availability | 99,5% (khớp tinh thần PLT-NFR-04) | CF SLA + health check; mất relay = degrade, không mất dữ liệu |
| Quy mô v1.1 | 8 member/phiên · mục tiêu 500 phiên đồng thời | DO scale ngang theo phiên — không phải giới hạn thiết kế |
| Chi phí ước tính | ~0–5 USD/tháng ở quy mô beta (Workers Paid $5 + DO duration) | Xem lại khi >10k phiên/tháng |

## 8. Phương án so sánh (đã cân nhắc)

**A. Cloudflare Workers + Durable Objects — ĐỀ XUẤT.** Ưu: session=DO map 1:1 với state machine, alarm = timer 15', hibernation rẻ, zero-ops, deploy bằng wrangler trong CI hiện có. Nhược: vendor-specific API (DO), không có region VN.
**B. Self-host Node.js (y-websocket tùy biến) trên VPS.** Ưu: chủ quyền tuyệt đối, region tùy chọn. Nhược: đội chỉ có A3 part-time — vận hành 24/7, TLS, scale, monitoring đều là chi phí thật; timer/state phải tự xây đúng. Giữ làm **đường lùi** — giao thức §4 độc lập hạ tầng nên chuyển được mà không sửa app.
**C. Managed realtime (Liveblocks/Ably/PartyKit).** Ưu: nhanh nhất. Nhược: role enforcement server-side theo đúng APP-AC-06 khó tùy biến sâu; dữ liệu qua hạ tầng bên thứ ba khó khai báo minh bạch theo APP-BR-06; chi phí theo MAU tăng sớm. Loại cho v1.1.

**Điểm chốt thiết kế bảo vệ tương lai:** app chỉ biết giao thức §4 (đã trừu tượng qua `CollabTransport` — APP-NFR-06); đổi A↔B không đụng client.

## 9. Kế hoạch thực thi (đề xuất cho A3, từ tuần 8)

| Tuần | Việc | Ra khỏi cửa khi |
|---|---|---|
| 8 | Scaffold Worker+DO, REST vòng đời phiên, token | Deploy staging; POST/join/end chạy; test token |
| 9 | WS frames, role enforcement, state machine + alarm, ring buffer | **Toàn bộ bảng §4.3 có integration test** (miniflare/workerd local); Viewer-update bị 403 ở relay |
| 10 | Presence, snapshot chunking, ping/latency, rate limit; nối app (`CloudflareCollabTransport` implement `CollabTransport`) | 3 client giả lập hội tụ; loadtest 8 member; bàn giao cho M5 app-side |

App-side (đã có sẵn từ M4/M5 design): relay mock theo giao thức này cho test Lớp 1; Lớp 2 chạy trên staging.

## 10. Câu hỏi mở — KẾT QUẢ CHỐT (PO, 04/08/2026)

1. **Region SIN cho beta:** ✅ chấp nhận. Tuyên bố minh bạch trong share sheet (gộp vào cảnh báo APP-BR-06: "…qua máy chủ relay đặt tại Singapore"). Xem lại khi có yêu cầu chủ quyền dữ liệu (GĐ3+, đường lùi self-host §8B).
2. **Domain share link:** ⏳ còn treo — duy nhất mục chưa chốt (PO/ops xác nhận quyền DNS `sol.io` vs dùng `share.sol.io.vn`). **Không chặn build**: tuần 8–10 dùng `*.workers.dev` staging; hằng số URL cấu hình một chỗ ở cả relay lẫn app.
3. **E2E encryption:** ✅ hoãn đến khi có identity system (GĐ3) đúng §6; APP-BR-06 giữ nguyên cảnh báo.
4. **8 member/phiên · TTL token 24h:** ✅ xác nhận.
5. **Ngân sách Cloudflare Workers Paid $5/tháng:** ✅ phê duyệt.

## 11. Truy vết

APP-FR-13 (state machine, độ trễ, degrade) → §4.2–4.3, §7 · APP-FR-14 (revoke≠end, Viewer chặn ở relay) → §4.1–4.2 · APP-AC-06 → §4.2 `update` + test tuần 9 · APP-BR-01 (mặc định Viewer) → §4.1 join · APP-BR-06 (cảnh báo relay, tối thiểu hóa dữ liệu) → §6 · ADR-A02 rev.2 (ranh giới CRDT) → §2.4 · ADR-A03 (Lớp 1 mock/Lớp 2 staging) → §9 · APP-NFR-06 (`CollabTransport` thay được) → §8 · PAUL-05 (relay không câm, deadline sớm) → toàn spec + §0.
