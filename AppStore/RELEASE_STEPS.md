# Đưa Klyra lên App Store: làm theo từ trên xuống

Làm tới bước nào thì chép khối nội dung ở bước đó. Các khối chữ dài (Description, Review Notes) nằm trong [metadata.md](metadata.md) để khỏi lệch nội dung — file này trỏ tới đúng mục.

| | |
|---|---|
| Tên trên store (App Name) | `Klyra: Xtream M3U IPTV Player` (điền ở bước 1) |
| Subtitle | `Your channels, playlists & EPG` (điền ở bước 2) |
| Tên dưới icon | `Klyra` |
| Bundle ID | `com.klyra.iptv.player` |
| Version / Build | `1.0.0` / `1`. Mỗi lần upload lại phải **tăng số build** |
| Thiết bị | **Chỉ iPhone** (`TARGETED_DEVICE_FAMILY = 1`) → không cần ảnh iPad |
| Ngôn ngữ trang store | Chỉ **English (U.S.)** |

> 🔎 **Hai constant trong code phải điền** (grep `TODO: RELEASE`):
> [`Klyra/Common/AppConstant/AppConstant.swift`](../Klyra/Common/AppConstant/AppConstant.swift) → `appId` (bước 1.3) và `policyLink` (bước 4).

---

## Bước 0. Chuẩn bị (làm một lần)

- [ ] Có tài khoản **Apple Developer Program** (99 USD/năm).
- [ ] **Link web cần có sẵn** (team chỉ định, dùng lại cho cả 3 ô):

  | Ô | Link | Dùng ở |
  |---|---|---|
  | Privacy Policy URL | `<điền>` — trang nên nhắc Klyra + "Data Not Collected" (Guideline 5.1.1) | bước 4 + code `policyLink` |
  | Support URL | `<điền>` — trang có cách liên hệ (email) | bước 5 |
  | Marketing URL | `<điền>` (không bắt buộc) | bước 5 |

- [ ] Xcode › Settings › Accounts: đăng nhập Apple ID của tài khoản Developer.
- [ ] **Vẽ xong icon** — đã có: [AppStore/AppIcon-1024.png](AppIcon-1024.png) (đã nhúng trong build, không cần tải lên riêng).
- [ ] **Chụp 3–5 ảnh màn hình** bằng dữ liệu demo tự tạo (xem bước 5). *Chưa có — cần làm.*

---

## Bước 1. Tạo app

**1.1** [developer.apple.com](https://developer.apple.com) › Certificates, Identifiers & Profiles › Identifiers › **+** › App IDs:
- Description: `Klyra`
- Bundle ID (Explicit): `com.klyra.iptv.player`

**1.2** [appstoreconnect.apple.com](https://appstoreconnect.apple.com) › Apps › **+ › New App**:

| Ô | Điền |
|---|---|
| Platforms | iOS |
| Name | `Klyra: Xtream M3U IPTV Player` |
| Primary Language | English (U.S.) |
| Bundle ID | `com.klyra.iptv.player` |
| SKU | `klyra-ios-001` (tự đặt, không hiện ra ngoài) |
| User Access | Full Access |

**1.3** Vào **General › App Information**, chép số **Apple ID** của app (~10 chữ số) và điền vào code **trước khi build** (bước 7):

```swift
// Klyra/Common/AppConstant/AppConstant.swift
static let appId = "<số Apple ID>"   // TODO: RELEASE — nút Share dùng số này
```

---

## Bước 2. General › App Information

**Subtitle** (30/30), dán vào ô *Subtitle* ngay dưới ô *Name*:

```text
Your channels, playlists & EPG
```

| Ô | Điền |
|---|---|
| Category | Primary: **Entertainment**. Secondary: **Photo & Video** |
| Content Rights | *"Does your app contain… third-party content?"* → **No** (app ship rỗng, mọi nội dung do người dùng tự nhập) |
| Age Rating (*Edit*) | Mọi mục nội dung: **None**. Unrestricted Web Access: **No**. User-Generated Content: **No**. Advertising: **No**. → thường **4+** |
| License Agreement | Để mặc định (**Apple Standard EULA**) |

Bấm **Save**.

---

## Bước 3. General › Pricing and Availability

| Ô | Điền |
|---|---|
| Price | **Free** (bản 1.0 không có In-App Purchase) |
| Availability | Các quốc gia muốn phát hành |
| iPhone and iPad Apps on Apple Silicon Macs | **Bỏ chọn** |

Bấm **Save**.

---

## Bước 4. General › App Privacy

| Ô | Điền |
|---|---|
| Privacy Policy URL | `<link ở bước 0>` — **và** điền cùng link vào code: `AppConstants.policyLink` (`TODO: RELEASE`) |
| Data Collection | *Get Started* → **No, we do not collect data from this app** → kết quả **Data Not Collected** |

⚠️ Đừng khai nhầm là có thu thập Device ID / tracking (Pinewave từng bị reject vì khai sai). App không có analytics/ads/tài khoản; thông tin Xtream lưu trong **Keychain** trên máy. App đã kèm sẵn `PrivacyInfo.xcprivacy` (tracking = false, no data collected, khai UserDefaults).

Bấm **Save** → **Publish**.

---

## Bước 5. iOS App › 1.0 Prepare for Submission

**Previews and Screenshots** — app **chỉ iPhone**:

| Ô trên App Store Connect | Kích thước | Bắt buộc |
|---|---|---|
| iPhone 6.9" Display | 1320×2868 | ✅ bắt buộc |
| iPhone 6.5" Display | 1284×2778 | tuỳ chọn |

Nên 3–5 ảnh: (1) danh sách kênh + chips, (2) player + EPG now/next, (3) Car mode, (4) lưới lịch EPG + nhắc, (5) thêm nguồn (Xtream/QR). Dùng **dữ liệu demo tự tạo**, không thương hiệu thật (tránh 5.2.3).

**Promotional Text** (169/170 — sửa được bất cứ lúc nào, không cần duyệt lại):

```text
Play the IPTV playlists you already own: paste an M3U link, add your Xtream login or scan a QR. Now/next guide, car mode, Picture in Picture and sleep timer. No sign-up.
```

**Description** (2362/4000): chép nguyên khối từ [metadata.md](metadata.md) › **mục 2 › Description**.

**Keywords** (97/100):

```text
live,m3u8,hls,xmltv,streaming,television,watch,smart,guide,reminder,voice,qr,car,offline,video,tv
```

| Ô | Điền |
|---|---|
| Support URL | `<link ở bước 0>` |
| Marketing URL | `<link ở bước 0>` (hoặc để trống) |
| Version | `1.0.0` |
| Copyright | `2026 <tên cá nhân hoặc công ty>` |
| App Icon | Tự lấy từ build, không cần tải lên |
| Build | Để trống, chọn ở bước 8 sau khi upload |

Ô **What's New** không có ở bản đầu tiên (từ 1.0.1 mới điền).

Bấm **Save**.

---

## Bước 6. App Review Information

| Ô | Điền |
|---|---|
| Sign-In Information | **Bỏ tích** "Sign-in required" (app không có tài khoản; Xtream là đăng nhập vào **máy chủ của người dùng**) |
| Contact Information | Họ tên, số điện thoại (+84…), email người Apple liên hệ. **Bắt buộc** |
| Attachment | Không cần |

**Notes**: chép nguyên khối từ [metadata.md](metadata.md) › **mục 4** (đã gồm: app là player-only, không kèm kênh (5.2.3); không thu thập dữ liệu (5.1.2); bước test bằng stream mẫu của Apple; giải thích quyền Camera=QR, Micro/Speech=tìm bằng giọng nói; lý do NSAllowsArbitraryLoads).

Bấm **Save**.

---

## Bước 7. Build và upload từ Xcode

1. [ ] `AppConstants.appId` đã điền (bước 1.3) — grep `TODO: RELEASE` để chắc không còn placeholder.
2. [ ] `AppConstants.policyLink` đã điền (bước 4).
3. [ ] Target **Klyra** › **Signing & Capabilities**: tích *Automatically manage signing*, chọn **Team** trả phí.
4. [ ] Xác nhận `TARGETED_DEVICE_FAMILY = 1` (chỉ iPhone — **không thể bỏ iPad sau khi đã phát hành kèm iPad**).
5. [ ] Xác nhận `PrivacyInfo.xcprivacy` **nằm trong app bundle**: Target › Build Phases › Copy Bundle Resources (hoặc kiểm tra trong .app sau khi archive).
6. [ ] `ITSAppUsesNonExemptEncryption = NO` đã có trong Info.plist (đã thêm) → không bị hỏi Export Compliance.
7. Thanh công cụ chọn **Any iOS Device (arm64)** → **Product › Archive**.
8. Organizer: **Validate App** → **Distribute App › App Store Connect › Upload**.
9. Chờ Apple xử lý build (~10–30 phút, có email).

---

## Bước 8. Gửi duyệt

1. Trang **1.0 Prepare for Submission** › mục **Build** → chọn build vừa upload.
2. **App Store Version Release**: chọn phát hành tự động khi được duyệt, hoặc thủ công.
3. **Add for Review** → **Submit to App Review** (thường 1–2 ngày).

Muốn cho người khác dùng thử trước: **TestFlight** với chính build đã upload.

---

## Việc cần làm trong CODE (grep `TODO: RELEASE`)

| File | Hằng số | Khi nào |
|---|---|---|
| `AppConstant.swift` | `appId` | sau bước 1.3 (có Apple ID) |
| `AppConstant.swift` | `policyLink` | sau bước 4 (có Privacy Policy URL) |
| `SettingsViewModel.swift` | `appVersion` | mỗi lần tăng version — giữ khớp `MARKETING_VERSION` |

---

## Checklist trước khi submit

- [x] Đổi tên + bundle id sang Klyra (`com.klyra.iptv.player`)
- [x] App icon 1024 (opaque, vuông)
- [x] Chỉ iPhone (`TARGETED_DEVICE_FAMILY = 1`)
- [x] `ITSAppUsesNonExemptEncryption = NO`
- [x] `PrivacyInfo.xcprivacy` (Data Not Collected)
- [ ] Điền `appId` + `policyLink` trong code
- [ ] Privacy Policy / Support URL do team chỉ định
- [ ] Chụp 3–5 ảnh màn hình (demo data)
- [ ] Tài khoản Developer + chọn Team trong Xcode
- [ ] (Nếu muốn) tra lại trùng tên "Klyra" + trùng cụm mô tả với app cùng team (xem metadata.md mục 5)

## Nếu bị reject

Đọc phản hồi trong mục *App Review*, sửa, **tăng số build**, làm lại từ bước 7. Rủi ro hay gặp với app IPTV: **5.2.3** (app bị coi như cung cấp nội dung) — phòng ngừa đã làm sẵn, xem [metadata.md](metadata.md) mục 5.
