#if MONETIZATION_ENABLED
//
//  NativeAllAdManager.swift
//  Guru cleaner
//
//  Manager tái sử dụng cho tất cả nativeAll placements.
//
//  Cách dùng trong bất kỳ view nào:
//
//  @StateObject private var nativeAd = NativeAllAdManager(placement: .similarPhoto)
//
//  // Trong .task hoặc .onAppear:
//  .task { nativeAd.load() }
//
//  // Hiển thị ad:
//  nativeAd.adView
//

import SwiftUI
import Combine
import ads_swift

// MARK: - Placement

enum NativeAllPlacement {
    case similarPhoto
    case livePhoto
    case screenshots
    case panoramas
    case oldPhoto
    case oldVideo
    case compressionComplete

    var isEnable: Bool {
        let config = RemoteConfigManager.shared.nativeAllConfig
        switch self {
        case .similarPhoto:       return config.similarPhoto
        case .livePhoto:          return config.livePhoto
        case .screenshots:        return config.screenshots
        case .panoramas:          return config.panoramas
        case .oldPhoto:           return config.oldPhoto
        case .oldVideo:           return config.oldVideo
        case .compressionComplete: return config.compressionComplete
        }
    }
}

// MARK: - Manager

class NativeAllAdManager: ObservableObject {
    @Published private(set) var viewModel: NativeAdViewModel?
    @Published var itemCount: Int = 0
    let placement: NativeAllPlacement
    let style: NativeAdViewStyle
    let requiresMinItems: Bool

    private static let minItemsToShowAd = 6

    init(placement: NativeAllPlacement, style: NativeAdViewStyle = .homeAd, requiresMinItems: Bool = true) {
        self.placement = placement
        self.style = style
        self.requiresMinItems = requiresMinItems
    }

    /// Cập nhật số lượng items — gọi khi data thay đổi
    func updateItemCount(_ count: Int) {
        itemCount = count
        // Load ad nếu đủ điều kiện và chưa load
        if count >= NativeAllAdManager.minItemsToShowAd && viewModel == nil {
            load()
        }
    }

    /// Gọi trong .task hoặc .onAppear của view
    func load() {
        guard placement.isEnable,
              AdUtil.config.nativeAll.isEnable,
              viewModel == nil else { return }
        if requiresMinItems {
            guard itemCount >= NativeAllAdManager.minItemsToShowAd else { return }
        }
        let vm = NativeAdViewModel(adUnitID: AdUtil.config.nativeAll.id)
        vm.refreshAd()
        viewModel = vm
    }

    /// View hiển thị native ad
    @ViewBuilder
    var adView: some View {
        if placement.isEnable,
           AdUtil.config.nativeAll.isEnable,
           (!requiresMinItems || itemCount >= NativeAllAdManager.minItemsToShowAd),
           let vm = viewModel {
            NativeContentView(nativeViewModel: vm, style: style)
        }
    }
}

#endif
