# SwiftBase — Hướng dẫn tái sử dụng cho app mới

Base code SwiftUI (iOS 16+) gồm **luồng khởi động hoàn chỉnh + điều hướng + AdMob**
sẵn sàng copy sang app mới:

> **Splash → Language → Intro (3 màn) → Home (TabView 4 tab)**

Tài liệu này mô tả kiến trúc, cách wiring ads, và **các bước copy sang app khác**.

---

## 1. Kiến trúc thư mục

```
SwiftBase/
├── App/                     # Điểm vào + điều phối luồng
│   ├── SwiftBaseApp.swift       # @main, hook openURL (chống app-open khi quay lại)
│   ├── AppDelegate.swift        # Firebase configure (prod/dev plist)
│   ├── AppPhase.swift           # enum: splash / language / intro / home
│   ├── AppFlowCoordinator.swift # state machine của luồng, đọc OnboardingStore
│   └── ContainerView.swift      # đổi màn theo coordinator.phase (cross-fade)
├── AppRouter/               # Router điều hướng generic (mỗi tab 1 stack)
│   ├── Navigation.swift         # push / pop / popToRoot / pop(to:)
│   ├── NavigationController.swift, NavigationView.swift, NavigationRoot.swift
│   ├── Destination.swift        # enum màn + map Destination → View
│   └── DestinationWrapper.swift, NavigationType.swift
├── Core/
│   ├── Ads/                 # Kit AdMob (AdMobModule đã tailor cho app)
│   │   ├── AdConfig/            # model decode Remote Config (ad_config, app_configs)
│   │   ├── Utils/              # AdUtil, InterHomeUtil, NativeAllAdManager, RewardAllUtil
│   │   ├── RemoteConfigManager.swift, AdjustManager.swift, UMPManager.swift
│   │   └── RevenueLogging.swift
│   └── Firebase/            # AnalyticsScreen + trackScreen modifier
├── Common/
│   ├── Models/             # AppLanguage, HomeTab, IntroPage
│   ├── Components/         # BasicHeaderView, PrimaryButton, LottieTapView
│   ├── Factory/           # Container+Navigation (DI), AppManager
│   └── AppConstant/       # AppConstants (appId, policyLink…)
├── Extensions/            # String+Localized, View+CardSurface
├── Services/              # OnboardingStore (UserDefaults)
├── Views/                 # Splash, Language, Intro, Home, Search, Favorites, Settings, TabView
└── Resources/             # Info.plist, Assets, Localizable (6 ngôn ngữ), Json (Lottie), GoogleService-Info*
```

**Phụ thuộc (SPM):** `ads-swift`, `GoogleMobileAds`, `firebase-ios-sdk` (Core + RemoteConfig +
Analytics), `AdjustSdk`, `UserMessagingPlatform`, `FBSDKCoreKit`/`FBAudienceNetwork`,
`Lottie (lottie-spm)`, `Factory`.

---

## 2. Luồng khởi động

`SwiftBaseApp` → `ContainerView` quan sát `AppFlowCoordinator.phase`:

| Phase | Màn | Chuyển tiếp |
|-------|-----|-------------|
| `.splash` | `SplashView` | `splashDidFinish()` → đã onboarding? `.home` : `.language` |
| `.language` | `LanguageView(.onboarding)` | `didSelectLanguage()` → `.intro` |
| `.intro` | `IntroView` | `finishOnboarding()` → `.home` |
| `.home` | `HomeTabView` | — |

Trạng thái onboarding + ngôn ngữ lưu trong `OnboardingStore` (UserDefaults). Returning user
bỏ qua language/intro, vào thẳng Home.

**Splash chạy `configAds()` (thứ tự BẮT BUỘC):**
1. `RemoteConfig.fetchAndActivate` (xong trước → mới có ad unit id)
2. `AdsManager.initialize(intervalShowInter:, nativeAdColorConfig:)`
3. `AdjustManager.initialize()` + test devices (DEBUG)
4. ATT + UMP consent
5. `inter_splash` (chờ đóng)
6. `initAppOpenAd(appopenResume, autoEnable: false)`
7. `setShouldShow(true)` → `splashDidFinish()`

Splash có **progress bar + % loading** chia theo từng bước thật.

---

## 3. Điều hướng (AppRouter)

Mỗi tab có 1 `Navigation` riêng (inject qua `Container.homeNavi` / `searchNavi` / …).
`AppManager.navi` trỏ tới navigation của tab đang active.

```swift
// Trong ViewModel (đã @Injected(\.app) private var app)
app.navi.push(.homeDetail(id: 7))      // push
app.navi.push(.language)                // push màn từ Settings
app.navi.pop()                         // back 1 cấp
app.navi.popToRoot(.root)              // về gốc
app.navi.push(.x, type: .fullScreenCover)   // hoặc .sheet(detents:)
```

**Thêm màn mới:** thêm case vào `Destination` enum → thêm `identifier` → map sang View trong
`Navigation.screen(for:)`.

**Ẩn tab bar ở màn con:** đã wire sẵn — `.toolbar(.hidden, for: .tabBar)` áp cho mọi màn
push trong `NavigationView.swift`. Màn gốc của tab vẫn giữ tab bar.

**Lưu ý:** router ẩn navigation bar hệ thống (`build()` có `.toolbar(.hidden, for: .navigationBar)`),
nên mỗi màn tự vẽ header bằng `BasicHeaderView`.

---

## 4. Quảng cáo (AdMob)

### Placements (`Core/Ads/AdConfig/AdUnitsConfig.swift`)
Universal: `appopenResume`, `interSplash`, `nativeLanguage`, `nativeLanguageSelect`,
`nativeIntro1`, `nativeIntro3`, `nativeAll`, `bannerAll`, `rewardAll`, `interAll`.
App-specific (ví dụ SwiftBase): `interHome`, `interBack`.

> **Thêm/bớt placement:** sửa **3 chỗ** trong `AdUnitsConfig.swift` — khai báo `var`,
> `CodingKeys`, và dòng decode trong `init(from:)`. Thiếu 1 chỗ là decode sai âm thầm.

### Vị trí gắn ads trong app này
| Màn | Loại | Placement |
|-----|------|-----------|
| Splash | Interstitial | `interSplash` |
| Language (onboarding) | Native | `nativeLanguage` (chưa chọn) → `nativeLanguageSelect` (đã chọn) |
| Language (từ Settings) | Native | `nativeAll` |
| Intro | Native | `nativeIntro1` (trang 0), `nativeIntro3` (trang cuối) |
| Home → Detail | Interstitial | `interHome` |
| Detail → back | Interstitial | `interBack` |
| Resume app | App-open | `appopenResume` |

### Hiển thị Native ad
```swift
@State private var vm: NativeAdViewModel?
// onAppear:
let c = AdUtil.config.nativeLanguage
if c.isEnable, vm == nil { let v = NativeAdViewModel(adUnitID: c.id); v.refreshAd(); vm = v }
// body:
if let vm { NativeContentView(nativeViewModel: vm, style: .nativeLargeMediaCtaTop) }
```
> **Mỗi placement 1 `NativeAdViewModel` riêng**, không dùng chung. Màu CTA lấy từ global
> `NativeAdColorConfig` set ở Splash (= `.accentColor`).

### Hiển thị Interstitial theo action
```swift
InterHomeUtil.instance.show(placement: .home) { [weak self] in
    self?.app.navi.push(.homeDetail(id: id))   // điều hướng trong callback
}
```
> Luôn gọi trên **user action** (tap), KHÔNG gọi trong `.onAppear` (sẽ double-count khi back).
> SDK tự throttle theo `intervalShowInter`.

### `isEnable` vs `enable`
**Mọi call-site PHẢI đọc `config.isEnable`** (không đọc thẳng `.enable`):
`isEnable = chưa bị review-block && enableAllAds && enable`.

### Review-gating (chặn ads khi đang App Store review)
- `AppConfig` đọc key Remote Config `app_configs`; `isInReview = appVersion (remote) != bundle version`.
- `AdUtil.adsInReviewPaths` = danh sách placement bị tắt khi review (interSplash, interAll,
  appopenResume, interHome, interBack…). Chặn theo **placement**, không theo `id`.
- Khi build được duyệt → cập nhật `appVersion` trên console khớp version public → cờ về false.

---

## 5. Đa ngôn ngữ

- File: `Resources/Localizable/<lang>.lproj/Localizable.strings` (6 ngôn ngữ).
- Dùng: `"key".localized` (đọc theo ngôn ngữ đã chọn trong UserDefaults, không cần restart).
- Đổi ngôn ngữ runtime: view quan sát `AppFlowCoordinator` (vd `@InjectedObject(\.appFlow)`)
  để re-render khi `coordinator.language` đổi.
- **Thêm key:** thêm vào cả 6 file. Thêm ngôn ngữ mới: thêm case vào `AppLanguage` + tạo
  thư mục `<code>.lproj`.

---

## 6. Analytics

`.trackScreen(.home)` trên mỗi màn → log `screen_view` (Firebase). Thêm màn mới: thêm case
vào `AnalyticsScreen` (`Core/Firebase/AnalyticsScreen.swift`).

---

## 7. Copy sang app mới — checklist

**A. Tạo project & SPM**
1. Tạo app SwiftUI (iOS 16+), copy thư mục `SwiftBase/` vào.
2. Thêm các SPM package ở mục 1.
3. Thêm `GoogleService-Info.plist` (+ `GoogleService-Info-dev.plist` nếu có target dev).

**B. Info.plist** (project bật `GENERATE_INFOPLIST_FILE = YES`)
- Trỏ `INFOPLIST_FILE = <App>/Resources/Info.plist` (giữ `GENERATE_INFOPLIST_FILE = YES` để
  Xcode merge key generated lên file của bạn).
- Trong `Resources/Info.plist` đặt: `GADApplicationIdentifier` (`ca-app-pub-…~…`),
  `NSUserTrackingUsageDescription`, `SKAdNetworkItems`, Facebook keys, URL scheme `fb<id>`.
  Để Info.plist trong `membershipExceptions` (không copy như resource).

**C. Định danh app**
- `AppConstants` (`Common/AppConstant`): `appId`, `policyLink`.
- `AdjustManager`: `appToken`, revenue event token.
- Bundle id + `MARKETING_VERSION` trong project.
- Rename `SwiftBaseApp`, đổi tên hiển thị, `AccentColor` (màu chủ đạo — dùng xuyên suốt).

**D. Remote Config (Firebase console)**
- Key `ad_config` (JSON chứa `adUnitsConfig` với `id`/`enable`/`opacity` từng placement,
  `intervalShowInter`, `showAllAds`).
- Key `app_configs` (chứa `appVersion` = version public đã duyệt, cho review-gating).
- **Quan trọng:** native/inter chỉ hiện khi `isEnable && id != ""`. Simulator luôn trả test ad.

**E. Tailor nội dung**
- `AdUnitsConfig`: xóa placement không dùng, thêm placement riêng (nhớ sửa đủ 3 chỗ).
- `AdUtil.adsInReviewPaths`: chọn placement chặn khi review.
- `IntroPage.all`: nội dung 3 slide intro.
- `AppLanguage`: danh sách ngôn ngữ + cờ.
- `Localizable.strings`: dịch toàn bộ key.
- `Destination` + `Views/`: thêm/sửa màn theo app.

---

## 8. Anti-patterns (tránh)
- ❌ `AdsManager.initialize` trước khi `fetchAndActivate` xong → unit id rỗng, ads im lặng.
- ❌ Hiện UMP/ATT trước `setIsExcludeScreen(true)` → app-open che popup consent.
- ❌ Quên `setShouldShow(true)` cuối splash → ads tắt vĩnh viễn.
- ❌ Inter trên mỗi lần đổi tab → khó chịu (app này cố tình KHÔNG làm).
- ❌ Dùng chung 1 `NativeAdViewModel` cho nhiều màn.
- ❌ Hardcode ad unit id trong Swift → phải lấy từ Remote Config.
- ❌ Inter trong `.onAppear` → double-count khi back. Gọi trên tap.
- ❌ Gate ads bằng `.enable` thay vì `.isEnable` → bỏ qua premium + review-block.
- ❌ Thiếu `NSUserTrackingUsageDescription` → crash khi gọi ATT.
- ❌ `GENERATE_INFOPLIST_FILE=YES` mà không trỏ `INFOPLIST_FILE` → key GAD bị bỏ qua → crash
  `GADInvalidInitializationException`.
```
