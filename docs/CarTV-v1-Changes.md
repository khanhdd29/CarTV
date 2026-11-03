# CarTV — v1 (local-only) · tổng kết vòng nâng cấp

Bám theo 2 app tham chiếu (local-only, **không Firebase/ads cho v1** như yêu cầu),
bỏ bớt tham vọng Xtream/EPG/cloud trong markdown ban đầu.

## Học được từ app tham chiếu
- **app662 (Flutter)**: KHÔNG dùng API/Xtream — chỉ HTTP GET file `.m3u` thô + parse,
  lưu local (Hive). 4 nguồn: url / file / device / stream.
- **Pinewave-iOS**: bản native Swift của chính app662 (SwiftUI + SwiftData, 0 dependency).
  → dùng làm hình mẫu: 16 ngôn ngữ, flag PNG, live-detection, timeout→next, PiP/AirPlay.
- **Bài học App Review**: Pinewave bị reject 5.2.3 vì hardcode link/tên kênh bên thứ ba
  → CarTV KHÔNG nhúng playlist mẫu có brand.

## Bảng màu (đã định — sửa 1 nơi: `Common/Theme/AppColors.swift`)
| Token | Giá trị | Dùng cho |
|---|---|---|
| **primary** | `#4A7CF5` (xanh dương, = AccentColor) | nút, tab chọn, link, nhấn |
| **secondary** | `#F59E0B` (amber) | badge, "play now", nhấn phụ |
| **background** | system (sáng/tối tự động) | nền màn hình |
| surface | secondarySystemBackground | thẻ, ô nhập, hàng list |
| favorite/live | `#EF4444` | tim, chip LIVE |
| text | label/secondary/tertiary | chữ (tự đổi theo dark mode) |

Brand = **xanh dương** (phân biệt với green của Pinewave). Đổi `primary` thì sửa luôn
`Assets.xcassets › AccentColor`.

## Đa ngôn ngữ — 16 thứ tiếng (giống Pinewave, bỏ Arabic vì RTL)
en, vi, fr, pt-BR, pt-PT, es, de, it?→(không), ru, tr, id, hi, bn, ko, ja, zh-Hans, zh-Hant.
- Flag là **PNG** trong `Assets.xcassets/Flags` (copy từ Pinewave), hiển thị ở Language + Settings.
- `Localizable.strings`: **16 file × 67 key**, đã qua `plutil -lint`. en/vi dịch tay;
  14 ngôn ngữ còn lại dịch tự động (native script) — nên nhờ người bản ngữ rà lại trước khi release.
- `AppLanguage` tự map ngôn ngữ máy (pt→pt-PT/BR, zh→Hans/Hant).

## Tính năng mới
1. **Đa nguồn nhập** (màn Add, segmented 4 tab):
   - **URL** M3U · **File** `.m3u/.m3u8` (Files) · **Stream** (dán link → Play now / Save) ·
     **Device** (chọn video từ Photos → lưu vào app → playlist "Device").
2. **Tab Recents** (lịch sử xem, cap 100, có nút xoá) — tab thứ 5.
3. **Player nâng cấp** (`PlayerController` + `AVPlayerEngine`):
   - Hàng đợi kênh **next/prev**, **LIVE chip** (duration indefinite), **timeout 15s → "Out of
     service"** với nút *Try again / Next channel*, **AirPlay** (AVRoutePickerView), **PiP +
     phát nền** (UIBackgroundModes `audio`), ghi **Recents** khi phát.
4. **Cache logo** `CachedAsyncImage` (NSCache + dedup) thay `AsyncImage` — không cần Kingfisher.
5. **VLCKit fallback** `VLCPlayerEngine` sau `#if canImport(MobileVLCKit)` — khi AVPlayer lỗi
   tự chuyển sang VLC. **Chưa bật** (chưa link package); build không cần nó.

## ⚠️ Build & bật tuỳ chọn
- Mở `Klyra.xcodeproj` (Xcode 26), để SPM resolve (lần trước đã resolve OK) rồi Run.
  File mới tự vào build (synchronized group) — không cần sửa `project.pbxproj`.
- **Bật VLCKit fallback**: File → Add Package Dependencies → `https://github.com/videolan/VLCKit`
  → product **MobileVLCKit**. Xong là tự hoạt động, không cần sửa code.
- Vẫn **không** Firebase/Firestore cho v1; ads là code template sẵn có, chưa đụng tới.

## Ads / Firebase / Adjust — GIỮ code, chỉ TẮT (không xoá)
Toàn bộ code monetization/analytics được **bảo toàn**, gói trong cờ biên dịch
`MONETIZATION_ENABLED` (không định nghĩa = tắt ở v1), nên build không cần package:
- `Klyra/Core/Ads/` (15 file) — khôi phục nguyên vẹn, mỗi file bọc `#if MONETIZATION_ENABLED … #endif`.
- 7 call-site (`SwiftBaseApp`, `AppDelegate`, `SplashView`, `IntroView`, `LanguageView`,
  `AnalyticsTracker`, `LottieTapView`) — nhánh ads/Firebase dưới `#if MONETIZATION_ENABLED`,
  nhánh v1 local-only chạy mặc định (`#else`).

**Bật lại khi cần** (3 bước):
1. Thêm lại SPM packages: `ads-swift` (bitbucket, cần credential), `firebase-ios-sdk`,
   `facebook-ios-sdk`, `ios_sdk` (Adjust) + link product cho 2 target.
2. Thêm `MONETIZATION_ENABLED` vào Build Settings → *Active Compilation Conditions*
   (hoặc `SWIFT_ACTIVE_COMPILATION_CONDITIONS`).
3. Báo mình "check luồng ads/firebase và mở lại" — mình rà call-site cho khớp.

> Lưu ý: tải Firebase/FB binary rất nặng (~GB) — cần đủ dung lượng ổ đĩa. Chỉ bật khi thật sự cần.

## Còn lại (sau này)
Rà bản dịch 14 ngôn ngữ; Xtream Codes login; EPG (XMLTV); health-check/auto-failover nhiều nguồn;
Chromecast; parental control; paywall.
