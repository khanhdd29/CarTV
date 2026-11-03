# CarTV — Giải thích tính năng (là gì & vì sao cần)

> Mục đích: giải thích **bằng ngôn ngữ thường** từng tính năng của app — nó **là gì**,
> **vì sao cần**, và **bạn nhìn thấy nó ở đâu**. Dành cho việc hiểu & quyết định, không
> phải tài liệu kỹ thuật. Bám đúng docs gốc (`CarTV-IPTV-App-Spec.md`), v1 **thuần local**
> (không server/Firebase).

## Bối cảnh 1 câu
App là **trình phát IPTV**: bạn nạp một **danh sách kênh** (file/link M3U), app hiện danh
sách và phát. Vấn đề của dòng app này: danh sách chỉ có *tên + link*, **không có** lịch
chương trình, không biết link nào còn sống, và link "lậu/free" **chết liên tục**. Các tính
năng bên dưới sinh ra để giải quyết đúng mấy nỗi đau đó.

---

## 1. Playlist M3U (nền tảng)
- **Là gì:** nạp danh sách kênh từ file `.m3u/.m3u8` hoặc link. Đây là cách chuẩn của mọi
  app IPTV.
- **Vì sao cần:** không có nó thì không có kênh để xem. App **ship rỗng** (không nhồi kênh
  sẵn) — vừa đúng luật App Store (tránh reject 5.2.3), vừa để người dùng tự thêm nguồn.
- **Thấy ở đâu:** nút **+** → URL / Tệp / Luồng / Video máy.

## 2. Xtream Codes + Keychain
- **Là gì:** một **cách đăng nhập khác** để lấy danh sách kênh. Nhiều nhà cung cấp IPTV
  không đưa link M3U mà đưa **máy chủ + tên đăng nhập + mật khẩu** (chuẩn "Xtream Codes").
  App gọi API của họ (`player_api.php`) để tải danh sách kênh.
- **Keychain là gì:** kho bảo mật của iOS. Tên đăng nhập/mật khẩu được lưu **ở đó**, mã hoá,
  **không bao giờ** để dạng chữ thường hay gửi lên đâu (yêu cầu bảo mật §6 của docs).
- **Vì sao cần:** nhiều người dùng chỉ có tài khoản Xtream chứ không có link M3U → thiếu nó
  là mất một nhóm người dùng. Keychain để không bị App Review soi "lưu mật khẩu bậy".
- **Thấy ở đâu:** nút **+** → **Xtream Codes** (nhập máy chủ/user/mật khẩu).

## 3. EPG — Lịch phát sóng (Electronic Program Guide)
- **Là gì:** "**Đang phát / Tiếp theo**" cho mỗi kênh, như lịch chương trình trên TV thật.
- **Vì sao không tự có:** file M3U **không chứa** lịch. Muốn có lịch phải nạp thêm **một
  nguồn riêng** gọi là **XMLTV** (file liệt kê: kênh X, 20:00–21:00, "Phim ABC"), rồi app tự
  ghép nó với kênh qua mã `tvg-id`. Vì phải tự nạp + tự ghép nên **đa số app free (662,
  Pinewave) không làm** → có nó là nhỉnh hơn nhóm đó.
- **Lưu ý thành thật:** đây là **chuẩn của app IPTV trả phí xịn**, không phải phát minh gì
  ghê gớm. Nó kéo app lên trên nhóm clone, không phải tính năng độc nhất.
- **Thấy ở đâu:** Cài đặt → **Lịch phát sóng** (dán link XMLTV) → khi xem sẽ thấy dải
  "ĐANG PHÁT / TIẾP THEO" trên màn hình phát.

## 4. Playlist Health Engine (sức khỏe kênh)
Đây là **nhóm tính năng khác biệt thật sự** còn lại so với 662/Pinewave và CarTV, mà vẫn
thuần local. Gồm 4 mảnh ăn khớp nhau:

### 4a. Probe (dò link)
- **Là gì:** gửi 1 request **rất nhẹ** tới link (xin ~2KB đầu, chờ tối đa 8 giây). Trả lời
  đúng 1 câu: **link còn sống hay đã chết?**
- **Không phải chất lượng video:** nó **không** đụng độ nét/bitrate. Chỉ đo *link có truy cập
  được không*, không đo *hình đẹp hay xấu*.

### 4b. Chấm trạng thái (xanh/đỏ)
- **Là gì:** mỗi card kênh có **chấm xanh (sống) / đỏ (chết)**; chưa dò thì không có chấm.
- **Vì sao cần:** playlist free có khi 1/3 kênh đã chết. Nhìn chấm là biết ngay, khỏi bấm
  thử từng cái.

### 4c. Auto-probe (dò nền tự động)  ← cái bạn hỏi
- **Là gì:** khi bạn mở Home/Tìm kiếm, app **tự âm thầm dò** những kênh **chưa biết** trạng
  thái (không dò lại cái đã biết, 6 link một lúc).
- **Vì sao cần:** nếu không có nó, chấm màu + "ẩn kênh lỗi" chỉ chạy khi bạn **bấm tay** nút
  "Kiểm tra". Auto-probe làm mọi thứ **tự động** — bạn không phải làm gì, chấm cứ tự hiện.
  Nó là "động cơ nền" khiến 4b và 4e hoạt động mà không phiền người dùng.

### 4d. Auto-failover (tự nhảy nguồn dự phòng)
- **Là gì:** đang xem mà link **chết giữa chừng**, player **tự nhảy** sang một kênh **trùng
  tên** (nguồn mirror) chưa thử, thay vì hiện lỗi.
- **Vì sao cần:** playlist IPTV hay có 1 kênh với nhiều link (vd "VTV3" xuất hiện 3 lần, 3
  link khác nhau). Link này sập thì tự chuyển link kia → xem liền mạch, không phải bấm lại.

### 4e. Ẩn kênh lỗi
- **Là gì:** công tắc trong Cài đặt; bật thì **giấu các kênh đã xác định chết** khỏi danh
  sách duyệt.
- **Vì sao cần:** để danh sách gọn, chỉ thấy kênh xem được. Dữ liệu "kênh nào chết" lấy từ
  4a/4c.
- **Thấy ở đâu:** Cài đặt → **Ẩn kênh lỗi**.

> Tóm lại cả nhóm 4: **app tự biết kênh nào chết (probe + auto-probe), cho bạn thấy (chấm
> màu), tự né khi đang xem (auto-failover), và dọn danh sách (ẩn kênh lỗi).**

## 5. Những tiện ích nền tảng khác (đã có)
| Tính năng | Là gì | Vì sao cần |
|---|---|---|
| **Yêu thích** | Lưu kênh hay xem | Khỏi tìm lại trong hàng trăm kênh |
| **Gần đây** | Kênh vừa xem | Quay lại nhanh |
| **Xem tiếp (resume)** | Video thường nhớ chỗ đang xem | Không phải tua lại từ đầu |
| **Tìm kiếm tức thì** | Gõ là ra (FTS5) | Playlist lớn, cuộn tay rất mệt |
| **16 ngôn ngữ** | Đa ngôn ngữ | Mở rộng thị trường |
| **AirPlay / xoay ngang** | Phát lên TV, toàn màn hình | Trải nghiệm xem TV đúng nghĩa |

---

## Chưa làm (để sau, theo docs)
- Auto-probe theo **lịch định kỳ** (hiện dò khi mở màn, chưa có cron nền).
- EPG **catch-up** (xem lại chương trình đã phát).
- Cloud sync / đăng nhập / paywall / Chromecast → docs xếp v2 và **cần server**, v1 bỏ qua.

## Nguyên tắc giữ xuyên suốt (vì sao quan trọng)
- **Thuần local**: không server, không Firebase ở v1.
- **Bảo mật**: mật khẩu → Keychain; không log link lên Analytics.
- **App ship rỗng**: không nhồi kênh/bản quyền vào app → tránh App Review reject (5.2.3).
- **Ads/Firebase/Adjust**: code **giữ lại nhưng tắt** (bọc cờ `MONETIZATION_ENABLED`), để bật
  lại sau mà không phải viết lại.
