#if MONETIZATION_ENABLED
//
//  AdUnitConfig.swift
//  AdmobSwitUI
//
//  Created by DucManh on 10/03/2026.
//

import Foundation

struct AdUnitConfig: Codable {
    var id: String = ""
    var enable: Bool = true
    var opacity: Int = 0
    var extraKeys: [String: Bool]?

    /// Slot của ad unit trong `AdUnitsConfig`, gán lúc decode (xem
    /// `AdUnitsConfig.init(from:)`). Dùng để chặn ads khi app đang bị review —
    /// chặn theo PLACEMENT, KHÔNG theo `id`, vì nhiều placement có thể dùng
    /// chung một ad unit id (chặn theo id sẽ tắt nhầm toàn bộ ads).
    /// Rỗng cho `AdUnitConfig()` mặc định (chưa qua decode).
    var placement: String = ""

    enum CodingKeys: String, CodingKey {
        case id, enable, opacity
        case extraKeys
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        enable = try container.decodeIfPresent(Bool.self, forKey: .enable) ?? true
        opacity = try container.decodeIfPresent(Int.self, forKey: .opacity) ?? 0
        extraKeys = try container.decodeIfPresent([String: Bool].self, forKey: .extraKeys)
    }

    init() {}
}

extension AdUnitConfig {
    /// Ad được phép hiển thị hay không. Thứ tự kiểm tra:
    ///   1. Review block — nếu placement nằm trong danh sách chặn-khi-review
    ///      (`RemoteConfigManager.adsInReviewBlockedPlacements`) → false.
    ///      Danh sách này RỖNG khi `isInReview = false`, nên ngoài lúc review
    ///      không ảnh hưởng gì.
    ///   2. Master switch (`enableAllAds`: premium tắt hết + cờ `showAllAds`)
    ///      kết hợp cờ `enable` riêng của từng unit.
    /// MỌI call-site show ad PHẢI dùng `isEnable`, không đọc thẳng `enable`,
    /// nếu không lớp review-gating sẽ không có hiệu lực ở chỗ đó.
    var isEnable: Bool {
        let mgr = RemoteConfigManager.shared
        if !placement.isEmpty,
           mgr.adsInReviewBlockedPlacements.contains(placement) { return false }
        return mgr.enableAllAds && enable
    }
}

#endif
