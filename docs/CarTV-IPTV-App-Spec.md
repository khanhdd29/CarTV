# IPTV / Media Player App — Idea & Technical Spec

> **Nền tảng:** iOS native (Swift / SwiftUI)
> **Hệ sinh thái sẵn có:** Firebase (Remote Config, Crashlytics, Analytics) → mở rộng dùng **Firestore + Auth**
> **Tham chiếu đối thủ:** CarTV — M3U IPTV Player & Cast (Lyntra Technology Ltd), và các IPTV player tương tự.
> **Mục đích tài liệu:** Mô tả ý tưởng, định vị sản phẩm, pain point, tính năng khác biệt, drivers kỹ thuật, công nghệ, bảo mật — đủ để một AI/dev đọc hiểu và triển khai trong một Swift codebase.

---

## Tư tưởng cốt lõi (đọc trước khi code)

1. **Đây là dòng app "Media Streaming Client / Playback Engine"** — giá trị nằm ở **player + networking + xử lý stream realtime**, KHÔNG phải ở CRUD/UI. Đối thủ cạnh tranh thật sự là **chất lượng & độ ổn định playback**, không phải số lượng feature.
2. **App chỉ là PLAYER, không cung cấp nội dung.** Người dùng tự nạp playlist/link. Backend KHÔNG bao giờ proxy/host luồng video (ranh giới pháp lý + chi phí bandwidth).
3. **Storage là plugin tháo lắp được.** Toàn bộ nghiệp vụ (Domain) chỉ phụ thuộc protocol. Hôm nay Firestore, mai Supabase, mốt backend riêng → đổi storage KHÔNG đổi nghiệp vụ. Đây là **Clean Architecture + Dependency Inversion**.
4. **Cloud chỉ giữ TRẠNG THÁI NGƯỜI DÙNG (nhẹ), không giữ NỘI DUNG (nặng).** Playlist 20k kênh ở local; Firestore chỉ giữ favourites/history/settings + link playlist.

---

## 0. Nó là dòng app gì?

Về bản chất: **Media Streaming Client / Playback Engine app** — nhóm app mà **lõi là xử lý media (playback), không phải xử lý dữ liệu (data)**.

Đặc điểm:
- Giá trị không nằm ở UI/CRUD mà nằm ở **player engine + networking + xử lý stream realtime**.
- Không có backend nội dung (app chỉ là client) → **mọi độ khó dồn vào phía client**.
- Cùng họ với: VLC, Infuse, nPlayer, TiviMate, IINA.

**"Car Mode" chỉ là vỏ marketing** để chiếm ngách ít đối thủ trên App Store. Ruột là IPTV player phổ thông — dùng được trên iPhone/iPad/TV, không chỉ cho người đi ô tô.

> ⚠️ App bị coi là "spam" vì chỉ bọc lại một player có sẵn rồi gắn paywall — không giải quyết pain point playback thật. Muốn khác biệt → phải thắng ở những bài toán **khó**.

---

## 1. Pain points thực tế của người dùng IPTV (gốc rễ để nâng cấp)

| Pain point | Vì sao đau | Cơ hội giải quyết |
|---|---|---|
| Link M3U chết / lag liên tục | Nguồn free không ổn định | **Auto-failover + health check** |
| Playlist 5.000–20.000 kênh → app lag/đơ | Parse + render naive | **Kiến trúc xử lý list lớn** |
| Không biết kênh nào đang chiếu gì | Thiếu EPG | **EPG + "đang phát"** |
| Buffer mãi, chất lượng kém | Không adaptive | **Buffering thông minh** |
| Mất playlist khi đổi máy | Chỉ lưu local | **Sync nhiều thiết bị** |
| Giao diện xấu, khó tìm kênh | App làm ẩu | **Search + lịch sử + đề xuất** |

→ Tìm sự khác biệt ở **giải quyết pain point**, không phải thêm nút.

---

## 2. Tính năng nâng cấp — nổi bật & khác biệt (xếp theo giá trị)

### 🔥 Nhóm A — Khác biệt lõi (làm app "không spam")

**A1. Playlist Health Engine (auto-failover)**
- App probe nền từng stream → đánh dấu kênh sống/chết.
- Kênh có nhiều nguồn backup → tự chuyển nguồn khi đứng hình.
- Tính năng app rác không có vì khó về kỹ thuật.

**A2. EPG (Electronic Program Guide)**
- "Đang phát / sắp phát", timeline như TV thật.
- Nhắc giờ, catch-up (xem lại nếu nguồn hỗ trợ).

**A3. Xử lý playlist cực lớn mượt mà**
- 20.000 kênh vẫn scroll 60fps, mở app < 1s.
- Bài toán kiến trúc (không nhìn thấy) nhưng giữ chân người dùng.

### ⭐ Nhóm B — Giữ chân (retention)

- **B1. Cloud sync** playlist (link) + favourites + lịch sử → đổi máy không mất gì (lý do gắn bó + lý do trả phí).
- **B2. Continue Watching / Recent / Recommend.**
- **B3. Parental control + profile** (nhà có trẻ con — pain point thật).
- **B4. Picture-in-Picture + AirPlay/Chromecast chuẩn.**

### 💡 Nhóm C — "Wow" tạo buzz

- **Multi-view**: 2–4 kênh cùng lúc (xem nhiều trận bóng).
- **Recording / timeshift**: tạm dừng kênh live, tua lại.
- **Smart search giọng nói.**

---

## 3. Drivers kỹ thuật của mỗi vấn đề (phần kiến trúc)

> "Driver" = yếu tố kỹ thuật quyết định độ khó & cách thiết kế.

### Driver 1 — Parsing & lưu trữ playlist lớn
- Vấn đề: file M3U ~20MB, 20k dòng, parse trên UI thread → đơ.
- Bản chất: **I/O-bound + CPU-bound parsing**.
- Giải pháp:
  - Parse **streaming** (đọc từng dòng, không load cả file vào RAM).
  - Chạy nền trong **background `Task` / `DispatchQueue`** (Swift) — không block main thread.
  - Lưu **SQLite có index** (GRDB/Core Data), KHÔNG giữ list trong memory.
  - UI dùng **lazy loading + virtualized list** (chỉ render phần nhìn thấy; SwiftUI `List`/`LazyVStack`).

### Driver 2 — Playback engine (phần sống còn)
- Bản chất: **codec support + adaptive bitrate + hardware decoding**.
- KHÔNG tự viết decoder. Dùng engine tối ưu sẵn:
  - **AVPlayer** (native HLS, hardware decode, tiết kiệm pin) — mặc định.
  - **VLCKit** (MobileVLCKit) — fallback cho MKV/HEVC/DTS và định dạng lạ.
- Kiến trúc **2 player tự fallback**: thử AVPlayer → lỗi/không hỗ trợ → chuyển VLCKit.
- Buffering thông minh: cấu hình buffer động theo tốc độ mạng.

### Driver 3 — Health check / failover
- Bản chất: **concurrency + network probing + backpressure**.
- Không probe 20k kênh cùng lúc → cần:
  - **Hàng đợi giới hạn concurrency** (10–20 song song) — `OperationQueue` / `TaskGroup` + semaphore.
  - Chỉ probe kênh đang xem / sắp xem (lazy), không probe mù.
  - Cache trạng thái + TTL (sống/chết trong X phút).

### Driver 4 — Sync nhiều thiết bị
- Bản chất: **state sync + conflict resolution + offline-first**.
- Firestore có offline cache sẵn → tận dụng, không tự code CRDT ở giai đoạn đầu.
- Conflict: last-write-wins theo timestamp là đủ cho favourites/history.

### Driver 5 — EPG
- Bản chất: **parse XMLTV (file rất lớn, `.xml.gz` vài chục MB) + ánh xạ kênh + múi giờ**.
- Parse nền + cache local. Fuzzy-match tên kênh (M3U và XMLTV hay lệch nhau).

---

## 4. Công nghệ, bên thứ 3, phí/quota (iOS Swift)

### Phía client (miễn phí, open source)

| Nhu cầu | Giải pháp iOS | Phí |
|---|---|---|
| UI | SwiftUI (hoặc UIKit) | Free |
| Player chính | **AVPlayer** (AVFoundation) | Free, native |
| Player fallback | **MobileVLCKit (VLCKit)** | Free, open source |
| Parse M3U | Tự viết, chạy background `Task` | Free |
| DB local | **GRDB (SQLite, có FTS5)** hoặc Core Data | Free |
| Secure credential | **Keychain** (`flutter_secure_storage` tương đương: Keychain Services / KeychainAccess) | Free |
| Cast | AirPlay (native) + Google Cast SDK | Free |
| Paywall | **StoreKit 2** hoặc **RevenueCat** | RevenueCat có free tier |

### Phía backend (hệ Firebase — thống nhất)

- **Firestore + Auth** (Sign in with Apple + Anonymous auth).
- Đã có sẵn: **Remote Config, Crashlytics, Analytics**.
- (Khi scale) **Cloud Functions for Firebase** cho health-check tập trung — cân nhắc sau, đắt hơn Cloudflare nếu probe nhiều.

### ⚠️ Bẫy chi phí Firestore (đọc kỹ)

- Firestore tính tiền theo **số document read/write**.
- **KHÔNG** lưu mỗi kênh 1 document (20k kênh = 20k reads mỗi lần mở app → cháy quota + chậm).
- Tách dữ liệu:

| Dữ liệu | Lưu ở đâu | Lý do |
|---|---|---|
| Playlist gốc (20k kênh) | **Local (GRDB/Core Data)** | Dữ liệu nặng, tái tạo được bằng parse lại link |
| Link playlist (metadata) | Firestore | Nhỏ, cần sync |
| Favourites, history, settings | Firestore | Nhỏ, cần sync |
| Credential Xtream/server | **Keychain** (KHÔNG lên cloud) | Bảo mật |

- **Không dùng realtime listener** (`addSnapshotListener`) cho app này. Dùng **fetch-on-launch (`getDocuments`) + write-on-change (debounce)** → vài read/write mỗi phiên, cực rẻ.
- Dùng **Remote Config** để bật/tắt tần suất sync; ghi theo **batch + debounce**, không ghi mỗi lần bấm favourite.

> Realtime listener = Firestore tự báo khi data đổi (vd đổi favourite máy A → máy B update ngay). Tiện nhưng app này gần như không cần → né để khỏi đội phí.

---

## 5. Kỹ thuật "hay ho" thay vì làm mức ổn

1. **Offline-first + sync**: client luôn chạy từ DB local, sync nền → mượt kể cả mất mạng (last-write-wins có timestamp).
2. **Edge computing cho health-check** (khi scale): server probe stream, trả trạng thái → client không tốn pin/mạng.
3. **Adaptive buffering** theo đo tốc độ mạng realtime.
4. **Full-text search** trên SQLite (**FTS5**) cho 20k kênh → tìm tức thời.
5. **Lazy EPG mapping** bằng fuzzy matching tên kênh.
6. **Prefetch**: đoán kênh tiếp theo, mở sẵn connection.
7. **Streaming parse** M3U (không load cả file vào RAM).

---

## 6. Bảo mật & tối ưu (các app rác thường bỏ qua)

### Bảo mật
- **Credential Xtream/server → Keychain**, KHÔNG để plaintext, KHÔNG lên Firestore.
- **Không log URL stream** ra Analytics (lộ nguồn + lộ danh tính người dùng).
- Mã hóa dữ liệu nhạy cảm local.
- **Certificate pinning** cho API backend riêng (nếu có).
- Sign in with Apple (bắt buộc nếu có login bên thứ ba khác).

### Tối ưu
- **Image caching** cho logo kênh (20k logo → không tải lại; `Kingfisher`/`Nuke`).
- Memory: **không bao giờ giữ full list trong RAM** — query theo trang từ SQLite.
- Pin: giới hạn probe nền, **tắt khi app vào background**.
- Khởi động lạnh **< 1s** bằng lazy load.
- Detach mọi listener/task khi background.

---

## 7. Kiến trúc hệ thống (Clean Architecture)

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                        │
│         SwiftUI Views + ViewModels (@Observable)              │
│   ChannelListView · PlayerView · FavouritesView · EPGView     │
└───────────────────────────┬───────────────────────────────────┘
                            │ gọi use cases
┌───────────────────────────▼───────────────────────────────────┐
│                      DOMAIN LAYER  ★ (lõi, KHÔNG đổi bao giờ)   │
│   Entities:   Channel, Playlist, Favourite, WatchHistory       │
│   UseCases:   AddPlaylist, PlayChannel, ToggleFavourite,       │
│               SyncUserData, CheckStreamHealth                  │
│   Protocols:  PlaylistRepository, UserDataRepository,          │  ← ABSTRACTION
│               PlayerEngine, StreamProber                       │
└───────┬───────────────────────────┬───────────────┬───────────┘
        │ implements                │ implements    │ implements
┌───────▼─────────┐  ┌──────────────▼───────┐  ┌─────▼──────────────┐
│   DATA LAYER     │  │    DATA LAYER        │  │  PLAYBACK LAYER     │
│ LocalPlaylistRepo│  │ FirestoreUserRepo    │  │ AVPlayerEngine     │
│  → GRDB/SQLite   │  │  → Firestore + Auth  │  │ VLCKitEngine       │
│  (20k kênh)      │  │  ⟳ CÓ THỂ THAY:      │  │ (fallback)         │
│                  │  │   SupabaseUserRepo   │  │ tự chọn theo codec │
│                  │  │   CustomApiUserRepo  │  │                    │
│                  │  │  Keychain (cred)     │  │                    │
└──────────────────┘  └──────────────────────┘  └────────────────────┘
        │                      │
   link M3U ngoài         Firebase (RemoteConfig,
   (HLS/HTTP)             Crashlytics, Analytics)
```

**3 nguyên tắc:**
1. **DOMAIN là trái tim** — chỉ biết protocol, không biết Firestore. Không đổi khi thay storage.
2. **Phụ thuộc chĩa VÀO TRONG** — Data layer phụ thuộc Domain. Vứt Firestore, cắm Supabase → Domain không biết.
3. **Tách 2 repo** — playlist (nặng → local) và user-data (nhẹ → cloud).

---

## 8. Lớp trừu tượng storage (code mẫu)

### 8.1. Domain protocol — "lớp cha bao trùm"

```swift
// DOMAIN LAYER — thuần Swift, KHÔNG import FirebaseFirestore.
// Đây là hợp đồng. Storage nào cũng phải tuân theo.

protocol UserDataRepository {
    func fetchFavourites() async throws -> [Favourite]
    func saveFavourite(_ fav: Favourite) async throws
    func removeFavourite(channelId: String) async throws

    func fetchHistory(limit: Int) async throws -> [WatchHistory]
    func recordWatch(_ item: WatchHistory) async throws

    func fetchSyncedPlaylists() async throws -> [PlaylistRef]
    func savePlaylistRef(_ ref: PlaylistRef) async throws

    func fetchSettings() async throws -> UserSettings
    func saveSettings(_ settings: UserSettings) async throws
}

// Entity thuần — không dính gì Firestore.
struct Favourite: Identifiable, Codable {
    let id: String          // = channelId
    let channelName: String
    let logoURL: String?
    let addedAt: Date
    let sortOrder: Int
}

struct PlaylistRef: Identifiable, Codable {
    let id: String
    let name: String
    let sourceURL: String   // ← chỉ lưu LINK, không lưu 20k kênh
    let type: PlaylistType  // m3u, xtream, server
    let addedAt: Date
}

enum PlaylistType: String, Codable { case m3u, xtream, server }
```

> ViewModel **chỉ gọi `UserDataRepository`**, không bao giờ gọi Firestore trực tiếp → đổi storage không đụng nghiệp vụ.

### 8.2. Implementation Firestore (hiện tại)

```swift
// DATA LAYER — chỗ DUY NHẤT import Firebase.
import FirebaseFirestore
import FirebaseAuth

final class FirestoreUserDataRepository: UserDataRepository {
    private let db = Firestore.firestore()
    private var uid: String { Auth.auth().currentUser?.uid ?? "" }

    func fetchFavourites() async throws -> [Favourite] {
        let snap = try await db
            .collection("users").document(uid)
            .collection("favourites")
            .getDocuments()                    // ← getDocuments, KHÔNG addSnapshotListener
        return snap.documents.compactMap { try? $0.data(as: FavouriteDTO.self).toDomain() }
    }

    func saveFavourite(_ fav: Favourite) async throws {
        try db.collection("users").document(uid)
            .collection("favourites").document(fav.id)
            .setData(from: FavouriteDTO(domain: fav))   // debounce ở tầng trên
    }
    // ... các hàm khác
}
```

> Mai đổi Supabase → chỉ viết `SupabaseUserDataRepository: UserDataRepository`, đổi 1 dòng ở DI container. Domain + UI không đụng một dòng.

### 8.3. Cấu trúc Firestore (tối ưu read/write)

```
users/{uid}
 ├── profile          (1 doc: displayName, createdAt, plan)
 ├── settings         (1 doc: player config, parental pin...)   ← gộp 1 doc
 ├── favourites/{channelId}     (mỗi favourite 1 doc nhỏ)
 ├── history/{autoId}           (giới hạn ~100 doc gần nhất)
 └── playlists/{playlistId}     (CHỈ metadata + link, KHÔNG kênh)
```

Nguyên tắc chi phí:
- Settings gộp **1 document** (1 read, không đọc từng field).
- History **giới hạn 100 bản ghi** (xóa cũ) → không phình vô hạn.
- Favourites < vài trăm → đọc 1 lần lúc mở app.
- Playlists **chỉ lưu link** → kênh parse lại ở local mỗi máy.

---

## 9. Lộ trình triển khai

### 🟢 MVP (4–6 tuần) — "Player chạy ngon, chưa cần cloud"
Mục tiêu: chứng minh **playback ổn định** — thứ quyết định sống chết.

- [ ] Thêm playlist bằng link M3U + parse (background `Task`, streaming parse).
- [ ] Lưu local (GRDB/Core Data) + list ảo hóa (mượt 20k kênh).
- [ ] Player: **AVPlayer** (HLS) — chưa cần VLCKit.
- [ ] Favourites + resume — **lưu LOCAL thôi** (qua `LocalUserDataRepository`).
- [ ] Search cơ bản (FTS5).
- [ ] Cắm sẵn Crashlytics + Analytics để đo thật.
- ✅ Code theo **Repository Pattern ngay từ đầu** để sau cắm cloud không phải sửa.

### 🔵 v1 — "Khác biệt + lý do trả tiền"
- [ ] **VLCKit fallback** (MKV/HEVC/DTS).
- [ ] **Auth** (Sign in with Apple + Anonymous).
- [ ] Cắm **`FirestoreUserDataRepository`** → sync favourites/history/settings (fetch-on-launch, write-on-change, debounce).
- [ ] **Stream health check** client-side (probe giới hạn concurrency).
- [ ] Credential Xtream → Keychain.
- [ ] Paywall (StoreKit 2 / RevenueCat), bật/tắt bằng Remote Config.

### 🟣 v2 — "Giữ chân + wow"
- [ ] **EPG** (parse XMLTV nền, fuzzy-match).
- [ ] **Auto-failover** (kênh nhiều nguồn tự chuyển).
- [ ] PiP + AirPlay/Chromecast.
- [ ] Parental control + profiles.
- [ ] Multi-view / timeshift.
- [ ] (Nếu số liệu cần) health-check lên Cloud Functions.

---

## 10. Checklist nguyên tắc (dán lên tường)

- [ ] Domain KHÔNG import Firebase. Chỉ Data layer import.
- [ ] Mọi truy cập storage qua **protocol repository**, không gọi SDK trực tiếp từ ViewModel.
- [ ] Playlist nặng ở **local**; cloud chỉ giữ **trạng thái người dùng + link**.
- [ ] KHÔNG realtime listener; dùng fetch-on-launch + write debounce.
- [ ] Credential ở **Keychain**, không ở cloud, không log URL stream.
- [ ] Parse & probe chạy **nền**, giới hạn concurrency, tắt khi background.
- [ ] Player 2 tầng: AVPlayer → VLCKit fallback.
- [ ] Không bao giờ proxy/host luồng video ở backend.
```
