# CarTV IPTV — MVP slice (ghi chú bàn giao)

Biến `SwiftBase` thành một **IPTV player** theo spec (`CarTV-IPTV-App-Spec.md`).
Lần này làm **lát cắt dọc chạy được**: dán link M3U → parse nền (streaming) → lưu
**SQLite + FTS5** → danh sách kênh ảo hoá → mở **AVPlayer** xem, kèm favourites &
search. Toàn bộ theo **Clean Architecture** để mở rộng (cloud sync, VLCKit, EPG…).

## App mẫu làm gì (để tham chiếu)
CarTV là IPTV player thuần client: người dùng tự nạp playlist M3U/Xtream, app duyệt
kênh theo nhóm, phát luồng live (HLS…), lưu yêu thích, cast (AirPlay/Chromecast),
EPG. App **không** cung cấp nội dung. Giá trị nằm ở player + xử lý list lớn + độ ổn
định, không phải CRUD. "Car mode" chỉ là vỏ marketing. → Ta làm app mới cùng dòng,
khác biệt ở chất lượng kỹ thuật (spec §0–§2).

## Kiến trúc & file mới (đều nằm trong `SwiftBase/`, auto-build nhờ synchronized group)

```
Domain/                         ★ thuần Swift, không import SDK/SQLite
  Entities/   Channel, PlaylistRef (+PlaylistType), Favourite
  AppError
  Repositories/  PlaylistRepository, UserDataRepository     (protocol — hợp đồng)
  UseCases/      AddPlaylistUseCase
Data/
  Local/  SQLiteDatabase (wrapper libsqlite3), IPTVStore (actor, schema+FTS5),
          LocalPlaylistRepository, LocalUserDataRepository
  Parser/ LineReader (đọc file theo chunk), M3UParser (streaming), PlaylistDownloader
Playback/   PlayerEngine (protocol 2 tầng), AVPlayerEngine (AVPlayer/HLS)
Common/Factory/  Container+IPTV (DI: đổi storage = đổi 1 dòng)
Common/Components/ ChannelRowView (dùng chung)
Views/  Home/ChannelsScreen+VM · AddPlaylist · Player · ManagePlaylists ·
        Search (FTS5) · Favorites  (Search/Favorites viết lại từ template)
```

Nguyên tắc đã tuân thủ (spec §7, §10):
- **Domain không biết SQLite/Firebase** — ViewModel chỉ gọi `PlaylistRepository` /
  `UserDataRepository`. Mai cắm Firestore chỉ thêm `FirestoreUserDataRepository` +
  đổi 1 dòng trong `Container+IPTV`.
- **Playlist nặng ở local** (SQLite). Parse **streaming**, insert theo **batch
  1.000** trong transaction, chạy trên **actor** (off main thread).
- **List ảo hoá + phân trang** 100 kênh/lần (không giữ full list trong RAM).
- **FTS5** search tức thời (`channels_fts`, external-content + trigger đồng bộ).
- **Player 2 tầng**: `PlayerEngine` protocol; hiện có `AVPlayerEngine`, chừa chỗ
  cắm `VLCKitEngine` (MKV/HEVC/DTS) sau.

## Đã sửa ở base
- `Destination`: thêm `.addPlaylist`, `.managePlaylists`, `.player(name,url,logo)`;
  bỏ `.homeDetail`. `.home` giờ map sang `ChannelsScreen`.
- `HomeTab`: tab Home → "Channels" (icon `tv.fill`).
- `AnalyticsScreen`: thêm `addPlaylist/managePlaylists/player`.
- `Settings`: thêm mục **Manage playlists**.
- `Info.plist`: thêm **ATS `NSAllowsArbitraryLoads`** (đa số stream IPTV là HTTP thuần).
- Localization: thêm key IPTV cho 6 ngôn ngữ (en/vi dịch chuẩn; de/es/fr/ja tạm EN).
- Đã xoá màn template: `HomeScreen/HomeViewModel/HomeDetail*`.

## ⚠️ Build
**Chưa build/verify được trong môi trường này**: SPM `ads-swift` là repo **private
trên bitbucket** → `xcodebuild` treo ở bước resolve (cần credential + mạng của bạn).
Mở `SwiftBase.xcodeproj` trong Xcode (26.x), để nó resolve packages rồi Run. Không
cần sửa `project.pbxproj` — file mới tự vào build (synchronized folder group).

Test nhanh: Channels → **+** → dán 1 link `.m3u`/`.m3u8` công khai → xem kênh chạy.

## Follow-up (ngoài lát cắt này, theo spec)
- Image caching cho logo (Kingfisher/Nuke) thay `AsyncImage`.
- VLCKit fallback; buffering thông minh; health-check/auto-failover.
- Auth (Sign in with Apple) + `FirestoreUserDataRepository` sync favourites/history.
- Xtream code & credential → Keychain. EPG (XMLTV). PiP + Chromecast. Paywall.
```
