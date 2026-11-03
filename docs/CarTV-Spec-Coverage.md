# CarTV — Đối chiếu Docs spec ↔ Đã triển khai

> Mục đích: trả lời "đã làm hết ý tưởng/kỹ thuật trong docs chưa". Bám **docs gốc**
> (`CarTV-IPTV-App-Spec.md`), KHÔNG lệch theo app tham khảo.

## 0. Quan hệ 3 app (cho rõ)
| App | Là gì | Publisher | Quan hệ |
|---|---|---|---|
| **CarTV — M3U IPTV Player & Cast** (id6800211040) | Đối thủ docs tham chiếu | **Lyntra Technology Ltd** | App ta định vị cạnh tranh |
| **app662** (`innofyapp-app662-iptv`, Flutter) | "IPTV Smart Player - Live TV" | **innofyapp** (white-label) | KHÁC CarTV; chỉ cùng dòng |
| **Pinewave** (Swift) | Bản viết lại native của app662 | — | = app662, KHÁC CarTV |

→ **662 và Pinewave KHÔNG phải CarTV** (tên chúng là "IPTV Smart Player", publisher innofyapp).
Chúng chỉ **cùng dòng** (M3U IPTV player + cast). CarTV là app của Lyntra. App ta: **đúng dòng
đó** (media playback client / M3U IPTV + cast), định vị như CarTV, theo kiến trúc docs.

---

## 1. Đã làm hết chưa? — KHÔNG. Mới xong **nền tảng MVP + kiến trúc**, phần khác biệt nâng cao chưa.

### ✅ ĐÃ LÀM (đúng docs)
| Docs | Trạng thái |
|---|---|
| Media playback client, app chỉ là PLAYER, không backend nội dung (§Tư tưởng 1-2) | ✅ |
| **Clean Architecture + Dependency Inversion**, storage là plugin qua protocol (§3, §7, §8) | ✅ Domain thuần, 2 repo (playlist local / user-data), đổi storage = 1 dòng DI |
| **Streaming parse** M3U, không load cả file vào RAM (Driver 1, §5.7) | ✅ LineReader + batch insert |
| Parse nền (background Task), **SQLite có index**, không giữ list trong RAM (Driver 1) | ✅ actor + SQLite, phân trang |
| **UI ảo hóa / lazy list** (Driver 1) | ✅ LazyVStack/rails |
| **FTS5 full-text search** 20k kênh (§5.4) | ✅ |
| **Player AVPlayer** (HLS, hardware decode) (Driver 2) | ✅ (đã chạy phát HLS thật) |
| **Player 2 tầng AVPlayer → VLCKit fallback** (Driver 2) | ✅ kiến trúc; VLCKit sau `#if canImport` (bật khi cắm package) |
| Favourites + local (§9 MVP) | ✅ |
| Recents / Continue Watching (§2 B2) | ✅ Recents + **resume vị trí phát** (lưu/khôi phục, bỏ qua live) → MVP đủ |
| **Image caching** logo (NSCache) (§6) | ✅ |
| Không giữ full list trong RAM — query theo trang (§6) | ✅ |
| AirPlay (§2 B4) | ✅ |
| PiP + phát nền | ✅ (UIBackgroundModes audio + VideoPlayer) |
| Không log URL stream ra Analytics (§6) | ✅ (Analytics đang tắt + không log URL) |

### 🟡 MỘT PHẦN
| Docs | Thiếu gì |
|---|---|
| Xử lý playlist 20k mượt (A3) | Kiến trúc đã sẵn; **chưa stress-test** thực tế 20k |
| Buffering thông minh / adaptive (Driver 2, §5.3) | Chưa cấu hình buffer động theo tốc độ mạng |

### ❌ CHƯA LÀM (docs xếp v1/v2 — differentiators)
| Docs | Phase |
|---|---|
| ~~**A1. Playlist Health Engine / auto-failover** (probe nền, đổi nguồn) (Driver 3)~~ → **ĐÃ LÀM**: probe link (GET Range, timeout 8s, 6 luồng song song) → lưu trạng thái local (bảng `stream_health`); chấm xanh/đỏ trên card kênh; nút "Kiểm tra" trong Quản lý danh sách phát (đếm hoạt động/lỗi); Player tự failover sang nguồn cùng tên khi link chết + đánh dấu online khi phát được. Probe tự động nền theo lịch chưa làm. | v2 |
| ~~**A2. EPG** (parse XMLTV, "đang phát", catch-up) (Driver 5, §5.5)~~ → **ĐÃ LÀM**: nhập link XMLTV ở Cài đặt → Lịch phát sóng, parse nền (SAX, cửa sổ −6h…+48h), lưu local (SQLite), hiện "Đang phát / Tiếp theo" trên Player (ghép theo tvg-id, có fallback theo stream URL). Catch-up chưa làm. | v2 |
| **B1. Cloud sync** (Firestore favourites/history/settings) (Driver 4) | v1 (kiến trúc đã sẵn qua `UserDataRepository`) |
| **Xtream Codes** login + **Keychain** cho credential (§4, §6, §8) | v1 |
| **Auth** (Sign in with Apple + Anonymous) (§9 v1) | v1 |
| **Paywall** (StoreKit2 / RevenueCat) (§4, §9 v1) | v1 |
| **Chromecast** (Google Cast SDK) (§2 B4, §4) | v2 |
| Parental control + profiles (§2 B3) | v2 |
| Multi-view / recording / timeshift / voice search (§2 C) | v2 |
| Prefetch kênh kế, adaptive buffering, edge health-check (§5) | sau |

---

## 2. Có lệch docs không? — KHÔNG.
- **Kiến trúc**: đúng Clean Architecture của docs (Domain/Data/Playback, Repository, 2 repo).
- **Tech**: dùng **SQLite+FTS5** (docs cho phép "GRDB hoặc Core Data"; raw SQLite+FTS5 tương đương, tốt cho 20k + FTS). KHÔNG bê SwiftData của Pinewave.
- **Player**: đúng "2 tầng AVPlayer→VLCKit" của docs.
- **UI**: hướng điện ảnh riêng của ta — KHÔNG clone 662/Pinewave.
- 662/Pinewave chỉ dùng để hiểu **luồng cơ bản** (add nguồn, tab, recents) — đã ghi nhận, không áp đặt tech.

## 3. Đề xuất thứ tự làm tiếp (bám docs)
- ✅ ~~Resume vị trí phát~~ — ĐÃ XONG → **MVP hoàn chỉnh**.
1. **Xtream Codes + Keychain** (nguồn phổ biến thứ 2 sau M3U; docs nhấn mạnh bảo mật credential; CarTV cũng có từ v1.1.0).
2. **EPG (XMLTV)** — "đang phát", khác biệt lớn (A2) — *CarTV còn CHƯA có → cơ hội vượt*.
3. **Health Engine / auto-failover** (A1) — khác biệt lõi "chống spam".
4. **Phụ đề + đổi audio track** (CarTV có; AVPlayer/VLCKit hỗ trợ sẵn).
5. **Cloud sync** (Firestore) — khi bật lại Firebase (đã tắt bằng cờ).
6. Chromecast, Paywall, Parental, Multi-view, Car-mode (v2).

## 4. CarTV (App Store) vs 662/Pinewave — khác gì
| | **CarTV** (Lyntra, id6800211040) | **662 / Pinewave** (innofyapp "IPTV Smart Player") |
|---|---|---|
| Nguồn | M3U/M3U8 + **Xtream** + **Jellyfin/Emby/Plex** + QR | M3U/M3U8 + file + device + stream lẻ |
| Decode | HW + **software fallback MKV/HEVC/DTS** | AVPlayer (Pinewave) / media_kit (662) |
| Phụ đề / audio track | ✅ (nhúng + ngoài, đổi audio) | ❌ |
| Resume | ✅ | ✅ (Pinewave) |
| **Car mode** (landscape, nút to, núm xoay) | ✅ (đặc trưng) | ❌ |
| **Cast to Car** (mirror màn hình lên xe) | ✅ (đặc trưng) | mirror cơ bản |
| Voice search | ✅ | ❌ |
| EPG | ❌ | ❌ |
| Monetize | IAP (lifetime/weekly/yearly) + tracking | Ads (662) / paywall (Pinewave) |

→ **662/Pinewave = player M3U cơ bản, white-label**, không có góc "xe". **CarTV = giàu hơn + xoáy vào Car mode / cast-to-car / Xtream / media server**. Cả hai **đều chưa có EPG** → docs (EPG + health engine) tham vọng hơn cả CarTV.
