# CarTV — Roadmap phần còn lại (sau MVP)

> Liệt kê **mọi thứ còn có thể làm**, **loại trừ** ads / Firebase / billing (IAP). Tất cả
> bên dưới đều **thuần local / mạng LAN**, không cần server. Bám docs gốc + bảng so sánh
> CarTV trong `CarTV-Spec-Coverage.md`.
>
> Đã xong: MVP (M3U, player HLS, favourites, recents, resume, search, AirPlay, 16 ngôn ngữ)
> + Xtream+Keychain + EPG (now/next) + Health Engine (probe/chấm/auto-probe/auto-failover/ẩn
> kênh lỗi).

## ❗ Đính chính: Chromecast KHÔNG cần Firebase/login
Google Cast chạy trên **mạng LAN** — app dò thiết bị Cast trong nhà rồi gửi link stream sang.
Không server, không đăng nhập. Nó nằm ngay trong tên app gốc ("...Player & **Cast**") → thuộc
nhóm nên-làm, không phải v2-vì-server.

---

## A. Nhóm "Xe / Cast" — đúng chất CarTV, khác biệt lõi
| # | Tính năng | Là gì / vì sao | Độ khó |
|---|---|---|---|
| A1 | **Chromecast / Google Cast** | Phát link lên TV/loa Cast qua LAN. Tên app có "Cast". | Vừa–cao (SDK ngoài) |
| A2 | **CarPlay** | App tên "CarTV" → hiện trên màn hình xe (ưu tiên audio + danh sách đơn giản). | Vừa |
| A3 | **Car mode** | Chế độ landscape nút to, tối giản khi lái (CarTV có, đặc trưng). | Thấp–vừa |

## B. Player nâng cao (local)
| # | Tính năng | Là gì / vì sao | Độ khó |
|---|---|---|---|
| B1 | **Phụ đề + đổi audio track** | Chọn phụ đề/âm thanh của luồng (CarTV có, 662/Pinewave không). | Vừa |
| B2 | **Picture-in-Picture thật + phát nền** | Thu nhỏ cửa sổ, nghe khi khoá máy (hiện mới một phần). | Thấp |
| B3 | **Tốc độ phát + hẹn giờ tắt** | Playback speed, sleep timer. | Thấp |
| B4 | **VLCKit software decode** | Giải mã MKV/HEVC/DTS khi AVPlayer thua (kiến trúc đã sẵn `#if canImport`, chỉ cắm package + bật). | Thấp (đã có khung) |
| B5 | **Adaptive buffering / prefetch kênh kế** | Đệm theo tốc độ mạng, nạp trước kênh kế (docs §5). | Vừa |

## C. Nguồn nội dung mới (local / HTTP)
| # | Tính năng | Là gì / vì sao | Độ khó |
|---|---|---|---|
| C1 | **Jellyfin / Emby / Plex** | Kết nối media server cá nhân (CarTV có). Client HTTP/LAN, không Firebase. | Cao |
| C2 | **Nhập bằng QR code** | Quét QR ra link playlist (CarTV có). | Thấp |
| C3 | **Quản lý playlist** | Đổi tên, sắp xếp, tự làm mới theo lịch, xuất/sao lưu ra Files. | Thấp–vừa |

## D. EPG mở rộng (local)
| # | Tính năng | Là gì / vì sao | Độ khó |
|---|---|---|---|
| D1 | **Lưới lịch (timeline/grid)** | Xem cả lịch ngày, không chỉ now/next. | Vừa |
| D2 | **Nhắc chương trình** | Đặt nhắc qua local notification. | Thấp |

## E. Health mở rộng (local)
| # | Tính năng | Là gì / vì sao | Độ khó |
|---|---|---|---|
| E1 | **Auto-probe theo lịch nền** | Dò sức khỏe định kỳ qua Background App Refresh (giờ mới dò khi mở màn). | Thấp–vừa |

## F. Tổ chức / trải nghiệm (local)
| # | Tính năng | Là gì / vì sao | Độ khó |
|---|---|---|---|
| F1 | **Khoá trẻ em (PIN)** | Chặn kênh/mục bằng mã PIN (local, không cần profiles-cloud). | Thấp |
| F2 | **Sắp xếp/lọc kênh, ẩn nhóm** | Tùy biến danh sách. | Thấp |
| F3 | **Tìm bằng giọng nói** | SFSpeech trên máy (CarTV có). | Vừa |
| F4 | **Multi-view** | Xem nhiều kênh cùng lúc. | Cao |
| F5 | **Widgets / Siri Shortcuts / Spotlight** | Truy cập nhanh ngoài app. | Vừa |
| F6 | **Accessibility / Dynamic Type / onboarding polish** | Hoàn thiện, dễ duyệt App Store. | Thấp |

## G. Phát hành (không viết code tính năng)
- Icon, ảnh chụp màn hình, mô tả, privacy nutrition label.
- Rà lại **5.2.3** (app ship rỗng, không nhồi kênh/bản quyền).
- Dọn i18n còn sót (vài key cũ dịch máy để nguyên tiếng Anh, vd hàng "Guide").
- Stress-test playlist lớn (~20k kênh).

---

## ⛔ Để sau vì CẦN ads/Firebase/billing (ngoài phạm vi hiện tại)
Cloud sync (Firestore), Sign in with Apple (chỉ có nghĩa khi có cloud sync), Paywall/IAP
(StoreKit), Ads, Remote Config, Analytics. Code liên quan đã **giữ nhưng tắt** bằng cờ
`MONETIZATION_ENABLED` — bật lại sau không phải viết lại.

## Gợi ý thứ tự (đúng chất "CarTV … & Cast")
1. **A1 Chromecast/Cast** + **A3 Car mode** — đúng tên app, khác biệt lõi, đều local.
2. **B1 Phụ đề/audio track** + **B2 PiP** — player ngang CarTV, dễ ăn điểm.
3. **A2 CarPlay** — đòn bẩy tên "CarTV".
4. **C1 Jellyfin/Plex** hoặc **D1 EPG grid** — tùy muốn giàu nguồn hay giàu lịch.
