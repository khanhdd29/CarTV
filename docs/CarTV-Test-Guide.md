# CarTV — Hướng dẫn tự test 4 nguồn nhập (URL · Tệp · Luồng · Thiết bị)

> ⚠️ Khi gõ link **trong Simulator**: đổi bàn phím Mac sang **English/ABC** (không để
> Tiếng Việt Telex) — nếu không "org" sẽ bị gõ thành "ờg", link sai → báo lỗi.
> Trên máy thật thì gõ bình thường.

---

## 1. URL — nhập link playlist M3U (nhiều kênh)
Dán vào ô "Đường dẫn M3U" → bấm **Thêm**. App tải + parse nền → ra danh sách kênh theo nhóm.

Link công khai (iptv-org, miễn phí):
```
https://iptv-org.github.io/iptv/countries/vn.m3u
```
```
https://iptv-org.github.io/iptv/categories/news.m3u
```
```
https://iptv-org.github.io/iptv/languages/vie.m3u
```
> Danh sách đầy đủ (rất lớn, ~10k kênh — test hiệu năng): `https://iptv-org.github.io/iptv/index.m3u`

## 2. Tệp — chọn file `.m3u` từ app Files
Nguồn này mở trình chọn file → chọn 1 file `.m3u`/`.m3u8` đã lưu trong máy.
Cách tạo file để test:
1. Mở Safari trong Simulator, vào 1 link M3U ở trên (vd `.../vn.m3u`).
2. Safari tải về → lưu vào **Files** (Tệp).
   (Hoặc kéo 1 file `.m3u` từ Mac vào cửa sổ Simulator để copy vào Files.)
3. Trong app → Thêm → **Tệp** → chọn file đó.

File M3U mẫu (tự tạo) — lưu thành `test.m3u`:
```
#EXTM3U
#EXTINF:-1 tvg-logo="" group-title="Demo",Big Buck Bunny
https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8
#EXTINF:-1 group-title="Demo",Apple Test
https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8
```

## 3. Luồng — dán 1 link stream lẻ (phát ngay hoặc lưu)
Dán 1 URL video/stream đơn → **Phát ngay** (mở player luôn) hoặc **Lưu** (thành playlist 1 kênh).

Link HLS/MP4 test (chạy được với AVPlayer):
```
https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8
```
```
https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8
```
```
https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4
```

## 4. Thiết bị — là gì? (câu bạn hỏi)
**"Thiết bị" = nhập video có sẵn trong máy (thư viện Ảnh)** để phát trong app, **offline**.
Tức app không chỉ xem IPTV mà còn chơi được **file video của chính bạn** (video bạn quay, tải về…).
- Bấm **Thiết bị** → trình chọn Ảnh hiện ra → chọn 1 hay nhiều video → app copy vào bộ nhớ app và tạo playlist "Thiết bị".
- Cách test trong Simulator: kéo 1 file `.mp4`/`.mov` từ Mac thả vào cửa sổ Simulator (nó lưu vào Ảnh), rồi vào app chọn.

> Nếu thấy chữ **"Thiết bị"** khó hiểu, mình có thể đổi nhãn thành **"Thư viện"** hoặc **"Video máy"** cho rõ nghĩa hơn. Cứ bảo mình.

---

## Ghi chú
- Đa số stream IPTV free hay **chết/lag** (nguồn không ổn định) → nếu 1 link không phát,
  thử link khác; app có timeout 15s rồi báo lỗi + cho "Thử lại / Kênh kế tiếp".
- Stream **live** (vd `.m3u8` không có điểm kết) sẽ hiện chip **LIVE** và ẩn thanh tua;
  stream **VOD** (có độ dài) thì hiện thanh tua + tua được + nhớ vị trí (resume).
