//
//  VLCPlayerEngine.swift
//  SwiftBase
//
//  Optional second-tier engine (spec §Driver 2). Compiles ONLY when the
//  MobileVLCKit package is linked — `#if canImport(MobileVLCKit)` — so the app
//  builds fine without it. To enable the fallback for MKV/HEVC/DTS/raw-TS and
//  other formats AVPlayer can't handle:
//
//    Xcode → File → Add Package Dependencies…
//    https://github.com/videolan/VLCKit  (product: MobileVLCKit)
//
//  Once linked, `PlayerController` automatically switches to VLC when AVPlayer
//  reports a failure. No other code changes needed.
//

#if canImport(MobileVLCKit)
import SwiftUI
import MobileVLCKit

@MainActor
final class VLCPlayerEngine: ObservableObject {
    let mediaPlayer = VLCMediaPlayer()

    func load(_ url: URL) {
        mediaPlayer.media = VLCMedia(url: url)
        mediaPlayer.play()
    }

    func stop() {
        mediaPlayer.stop()
    }
}

/// SwiftUI host for VLC's drawable surface.
struct VLCVideoSurface: UIViewRepresentable {
    let engine: VLCPlayerEngine

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        engine.mediaPlayer.drawable = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#endif
