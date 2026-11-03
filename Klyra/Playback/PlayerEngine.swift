//
//  PlayerEngine.swift
//  SwiftBase
//
//  PLAYBACK layer. The app plays through this protocol so the engine can be
//  swapped per codec (spec §Driver 2: AVPlayer default → VLCKit fallback for
//  MKV/HEVC/DTS). The MVP slice ships `AVPlayerEngine` only; a future
//  `VLCKitEngine` conforms to the same protocol and the player screen picks one.
//

import Foundation

enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case failed(String)
}

@MainActor
protocol PlayerEngine: AnyObject {
    var state: PlaybackState { get }
    func load(_ url: URL)
    func play()
    func pause()
    func teardown()
}
