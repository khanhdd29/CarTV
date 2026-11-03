//
//  PlayerLayerView.swift
//  SwiftBase
//
//  Hosts an AVPlayerLayer directly (no AVKit controls) so the app draws its own
//  controls without the system transport buttons overlapping them.
//

import SwiftUI
import AVFoundation

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    var pip: PiPManager? = nil

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        if let pip { Task { @MainActor in pip.setup(with: view.playerLayer) } }
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
        if let pip { Task { @MainActor in pip.setup(with: uiView.playerLayer) } }
    }
}

final class PlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
