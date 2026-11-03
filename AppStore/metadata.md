# Nội dung App Store: Klyra

Trang store **chỉ có tiếng Anh** (English U.S.) — giống Pinewave: không thêm bản địa hoá khác, App Store dùng bản tiếng Anh cho mọi quốc gia. Việc này **không** ảnh hưởng ngôn ngữ trong app: app vẫn có đủ 16 bản dịch, và mục Languages trên trang store vẫn tự liệt kê. (Phần VI đi kèm trong file Excel là bản dự phòng nếu team quyết định thêm trang tiếng Việt.)

Nội dung viết **riêng cho Klyra**, không chép lại câu chữ của app cùng team (Pinewave, Nexa, Lumenio, Fluxio, Streamora) để tránh Guideline 4.3 (Spam). Mọi tính năng trong bài đều đã đối chiếu với code; các ô có giới hạn ký tự đã đếm (xem mục 7). Chép từng khối vào App Store Connect.

Điểm khác biệt chính của Klyra so với Pinewave: **hỗ trợ Xtream Codes**, **EPG lưới lịch + nhắc chương trình**, **Car mode**, **quét QR**, **tìm bằng giọng nói**, **kiểm tra sức khoẻ kênh nền**, **khoá PIN trẻ em**. ASO nhấn các từ khoá này để không trùng cụm với các app kia.

## 1. Thông tin chung (App Information / Pricing / App Privacy)

| Mục | Giá trị |
|---|---|
| Bundle ID | `com.klyra.iptv.player` (đã tra iTunes 03/11/2026: trống) |
| Display name (dưới icon) | `Klyra` |
| Primary Language | English (U.S.). Không thêm ngôn ngữ nào khác cho trang store |
| Thiết bị | ⚠️ Project hiện đặt `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone **+ iPad**). Pinewave chỉ iPhone. **Một khi phát hành bản có iPad thì KHÔNG bỏ iPad đi được nữa** — nếu chưa làm UI cho iPad, nên đổi về `1` (chỉ iPhone) trước khi submit. Xem mục 6. |
| Danh mục chính / phụ | Entertainment / Photo & Video |
| Giá | Free. Bản 1.0 không có In-App Purchase (code ads/billing giữ nhưng tắt sau `#if MONETIZATION_ENABLED`) |
| Xếp hạng tuổi | Mọi mục nội dung (bạo lực, người lớn…) chọn **None** — app không kèm nội dung nào. Unrestricted Web Access: **No**. User-Generated Content: **No**. Advertising: **No**. Kết quả thường là **4+** |
| App Privacy | **Data Not Collected**. App không có analytics, quảng cáo hay tài khoản; mọi dữ liệu (playlist, yêu thích, lịch sử, thông tin đăng nhập Xtream) nằm trên máy. Thông tin Xtream lưu trong **Keychain**. ⚠️ Đừng khai nhầm là có thu thập Device ID (Pinewave từng bị reject vì khai sai mục này) |
| Privacy Policy URL | Bắt buộc. Dùng trang policy do team chỉ định; nội dung trang cần nhắc "Klyra không thu thập dữ liệu" cho khớp khai "Data Not Collected" (Guideline 5.1.1) |
| License Agreement (EULA) | Dùng **Apple Standard EULA** (mặc định) |
| Support URL | Bắt buộc. Dùng site liên hệ của team |
| Marketing URL | Không bắt buộc |
| Copyright | `2026 <tên cá nhân hoặc công ty>` |
| Sign-in for review | Không cần (app không có tài khoản). Xtream là đăng nhập vào **máy chủ của người dùng**, không phải tài khoản Klyra |

## 2. Nội dung trang store (English U.S.)

**App Name** (tối đa 30, hiện 29). Tên hiển thị dưới icon vẫn là `Klyra`; dòng này chỉ là tên trên trang store.
- Dẫn đầu bằng **"Xtream M3U"** (khác biệt so với Pinewave "IPTV Player for M3U") rồi tới **"IPTV Player"** (cụm tìm nhiều nhất). App Store ghép chữ trong tên, nên khớp cả "iptv", "iptv player", "m3u player", "xtream".
- Cấu trúc **khác** các app IPTV cùng team để tránh 4.3: Pinewave không có "Xtream", nên tên dẫn bằng Xtream là điểm nhận diện riêng.
- Cần tra lại trước khi submit: chưa app nào dùng chữ "Klyra" (store US/VN/GB/DE/JP) và cụm "Xtream M3U IPTV Player".

```text
Klyra: Xtream M3U IPTV Player
```

**Subtitle** (tối đa 30, hiện 30). Thêm chữ chưa có trong tên ("channels", "playlists", "EPG"). "Your" nhấn nguồn là **của người dùng** (giảm rủi ro 5.2.3). Không dùng "Live TV"/"Free TV" vì dễ hiểu là app cung cấp truyền hình.

```text
Your channels, playlists & EPG
```

**Promotional Text** (tối đa 170, hiện 169). Ô này không tính khi xếp hạng tìm kiếm, sửa được bất cứ lúc nào mà không cần gửi duyệt lại.

```text
Play the IPTV playlists you already own: paste an M3U link, add your Xtream login or scan a QR. Now/next guide, car mode, Picture in Picture and sleep timer. No sign-up.
```

**Keywords** (tối đa 100, hiện 98). Không lặp chữ đã có trong tên/subtitle (Apple không tính lặp), không dùng tên app khác, không "free/movies/sports" (gợi ý có sẵn nội dung), không "cast/chromecast" (Klyra chưa hỗ trợ).

```text
live,m3u8,hls,xmltv,streaming,television,watch,smart,guide,reminder,voice,qr,car,offline,video,tv
```
<!-- 97 ký tự -->


**Description** (tối đa 4000, hiện ~2180):

```text
Klyra is a fast, private player for the IPTV playlists and live streams you already have. Add a link, a file or your Xtream Codes login and your channels arrive sorted, searchable and ready to play — no account, no sign-up.

Klyra is only a player. It does not run, host or sell any channels, and it ships with no playlists, catalogs or channel lists of its own. Everything you watch comes from sources you add yourself, so please only use playlists and logins you are allowed to.

ADD YOUR SOURCE
- Paste an M3U or M3U8 link from the web
- Open an .m3u file from Files, or shared to Klyra from another app
- Sign in with Xtream Codes (host, username, password), kept only in the device Keychain
- Scan a QR code that holds a playlist link
- Pick a video from your library, or enter a single stream URL

FIND A CHANNEL FAST
- Group chips built from your playlist narrow a long list in one tap
- Search by name as you type, or hold the mic and say it out loud
- Tap the heart to keep favorites; recently played channels are remembered
- Sort A to Z, and hide channels that are offline

AN ON-SCREEN GUIDE
- Add an XMLTV link and Klyra shows what is on now and next for each channel
- Open a channel's full day schedule
- Set a reminder and Klyra notifies you before a programme starts

BUILT FOR WATCHING
- Car mode gives big, simple controls for a glance-and-go layout
- Keep playing in Picture in Picture while you use other apps
- Pick a subtitle or audio track when the stream carries them
- Change playback speed for recordings, or set a sleep timer
- If a channel stalls, Klyra moves on to a working backup on its own
- A LIVE tag marks live feeds; previous and next jump between channels
- Data saver caps the bitrate so you use less on mobile data

HEALTHY CHANNELS
Klyra quietly checks your channels in the background and marks the ones that are up, so a dead link is easy to skip.

A LOCK FOR LITTLE HANDS
Set a PIN to keep the app behind a parental lock.

YOUR DATA STAYS WITH YOU
No accounts, no ads and no analytics. Your playlists, favorites, history and any Xtream login stay only on your iPhone — the login held in the Keychain.

IN YOUR LANGUAGE
Klyra opens in your iPhone's language when it can, and you can switch any time in Settings. It speaks 16 languages.

Download Klyra and bring the playlists you already use into one calm, quick player.
```

**What's New in This Version**:

```text
First release of Klyra.
```

## 3. Icon và ảnh chụp màn hình

- Icon app: `AppStore/AppIcon-1024.png`, 1024×1024, không nền trong suốt, không bo góc (Apple tự bo). App Store lấy icon từ bản build nên **không cần tải file này lên** — file để lưu trữ/gửi designer. (Chưa có: cần vẽ icon cho Klyra.)
- Ảnh chụp dùng **dữ liệu demo tự tạo**: tên kênh, logo và hình video do app vẽ ra, **không có thương hiệu thật** (tránh 5.2.3). App ship rỗng nên phải seed dữ liệu demo khi chụp.
- Ô **iPhone 6.9" Display** (1320×2868) là bắt buộc; 6.5" (1284×2778) tuỳ chọn. Cần 3–5 ảnh: (1) danh sách kênh + chips, (2) player + EPG now/next, (3) Car mode, (4) lưới lịch EPG + nhắc, (5) thêm nguồn (Xtream/QR).
- Nếu bật iPad (mục 1) thì phải thêm bộ ảnh iPad 13"; đây là lý do nên cân nhắc chỉ iPhone cho v1.

## 4. Ghi chú cho người duyệt (App Review Information › Notes)

```text
Klyra is a player only. It ships with no channels, playlists, catalogs or discovery features of any kind, and it does not link to any IPTV provider. Users type or paste their own M3U playlist, .m3u file, Xtream Codes login, QR code, video or stream link.

Guideline 5.2.3: the app contains no third-party playlist names or URLs. The in-app guide tells users to get their link from their own IPTV provider; it does not point them to search engines or public channel lists.

Guideline 5.1.2(i): the app collects no data and does not track users. No analytics, no advertising, no third-party tracking SDKs. App Privacy is set to "Data Not Collected", so App Tracking Transparency does not apply. Xtream Codes credentials are stored only in the device Keychain.

Steps to test:
1. Launch the app, pick a language and go through onboarding.
2. Add tab (+) > Stream. Paste this Apple sample stream, type any name and play it:
   https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8
3. Open the saved item and play. The player offers Picture in Picture (on a real device), subtitle/audio track selection when the stream provides them, playback speed, a sleep timer, car mode and automatic retry on a dead link.

Permissions: Camera is used only to scan a QR code that holds a playlist link. Microphone and Speech Recognition are used only for voice search of channel names. The app asks for each only when you use that feature.

NSAllowsArbitraryLoads is enabled because many playlists and streams that users own are served over plain HTTP. The app only connects to addresses the user enters or opens.
```

## 5. Đã kiểm tra để tránh reject

- **App không cung cấp nội dung (5.2.3):** câu miễn trừ đặt ngay đoạn thứ hai của mô tả; app ship rỗng, không có tên/kênh bên thứ ba trong file; màn Hướng dẫn nói "lấy link từ nhà cung cấp IPTV của bạn", không trỏ tới công cụ tìm kiếm. Từ khoá không có "free/movies/sports".
- **Mô tả đúng với app (2.3.1):** từng dòng đã đối chiếu code — Xtream Codes + Keychain, M3U/M3U8/file/stream/QR, nhóm/chips, tìm theo tên + giọng nói, yêu thích/gần đây, sắp xếp A–Z, ẩn kênh offline, EPG now/next + lịch cả ngày + nhắc chương trình, Car mode, PiP, chọn phụ đề/âm thanh, tốc độ phát, hẹn giờ tắt, auto-failover, nhãn LIVE, kênh trước/sau, tiết kiệm dữ liệu, kiểm tra sức khoẻ nền, khoá PIN. **Không** nhắc AirPlay/Chromecast (Klyra v1 chưa làm cast) để khỏi lệch mô tả.
- **Trùng lặp với app cùng team (4.3):** tên và mô tả viết lại hoàn toàn, dẫn bằng Xtream/EPG/Car mode — các tính năng Pinewave không có. Trước khi submit nên so mô tả theo cụm 4 từ liên tiếp với Pinewave và 2 app Streamora (mục 7).
- **Quyền riêng tư:** cần có `PrivacyInfo.xcprivacy` và `ITSAppUsesNonExemptEncryption = NO` trong Info.plist trước khi archive (kiểm tra lại — xem mục 6).

## 6. Việc còn phải làm trước khi submit

1. **Quyết định iPhone-only hay iPhone+iPad.** Hiện là `"1,2"`. Nếu chưa làm/kiểm UI iPad, đổi `TARGETED_DEVICE_FAMILY = 1` (không thể bỏ iPad sau khi đã phát hành kèm iPad).
2. **Vẽ icon Klyra** 1024×1024, cập nhật `Assets.xcassets/AppIcon`, rồi copy ra `AppStore/AppIcon-1024.png`.
3. **Privacy Policy + Support URL** do team chỉ định; nội dung trang nên nhắc Klyra + "Data Not Collected".
4. **Kiểm `PrivacyInfo.xcprivacy` và `ITSAppUsesNonExemptEncryption`** đã có trong bản Klyra (bê từ template — cần xác nhận).
5. **App Store ID**: sau khi tạo app trên App Store Connect, điền vào hằng số App Store ID trong code để nút Share trỏ đúng.
6. Có tài khoản Apple Developer, chọn Team trong Xcode › Signing, đăng ký bundle ID `com.klyra.iptv.player`, tạo app (Primary Language: English U.S.), điền mục 1–4.
7. Chụp 3–5 ảnh với dữ liệu demo, Archive › Distribute › App Store Connect, gửi duyệt.

## 7. Kết quả đếm ký tự (EN)

| Ô | Hiện tại | Giới hạn |
|---|---|---|
| App Name | 29 | 30 |
| Subtitle | 30 | 30 |
| Promotional Text | 169 | 170 |
| Keywords | 97 | 100 |
| Description | 2362 | 4000 |
| What's New | 23 | 4000 |

- Số đếm lấy từ `AppStore/count_metadata.py` (chạy lại sau mỗi lần sửa chữ).
- Từ khoá không lặp chữ trong tên/subtitle (klyra, xtream, m3u, iptv, player, your, channels, playlists, epg).
- Chưa tra trùng tên "Klyra" + trùng cụm mô tả với app cùng team — làm trước khi submit (mục 5).
