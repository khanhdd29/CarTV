//
//  AVPlayerEngine.swift
//  SwiftBase
//
//  Default engine: native AVPlayer (hardware HLS decode, battery friendly).
//  - Detects LIVE streams with no extra request (item duration is indefinite).
//  - 15s load timeout → `.failed` so dead IPTV links surface quickly and the
//    player can offer "try again / next channel" (spec §Driver 2–3).
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class AVPlayerEngine: ObservableObject, PlayerEngine {
    @Published private(set) var state: PlaybackState = .idle
    /// `true` once a ready item reports an indefinite duration (live HLS).
    @Published private(set) var isLive = false
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0

    let player = AVPlayer()

    private var statusObservation: NSKeyValueObservation?
    private var failureObserver: NSObjectProtocol?
    private var timeoutTask: Task<Void, Never>?
    private var timeObserver: Any?

    /// Seconds to wait for a stream to become ready before declaring it dead.
    private let loadTimeout: UInt64 = 15_000_000_000

    init() {
        configureAudioSession()
        // Drive the scrubber / play state.
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main
        ) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds.isFinite ? time.seconds : 0
            let d = self.player.currentItem?.duration.seconds ?? 0
            self.duration = (d.isFinite && d > 0) ? d : 0
            self.isPlaying = self.player.timeControlStatus == .playing
        }
    }

    deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
    }

    func togglePlayPause() {
        if player.timeControlStatus == .playing { player.pause() } else { player.play() }
    }

    /// Skip forward/back by `delta` seconds.
    func skip(_ delta: Double) {
        seek(to: max(0, currentSeconds + delta))
    }

    func load(_ url: URL) {
        teardownObservers()
        timeoutTask?.cancel()
        state = .loading
        isLive = false

        let item = AVPlayerItem(url: url)
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.timeoutTask?.cancel()
                    self.isLive = item.duration.isIndefinite
                    self.state = .playing
                case .failed:
                    self.timeoutTask?.cancel()
                    self.state = .failed(item.error?.localizedDescription ?? "playback_error".localized)
                default:
                    break
                }
            }
        }
        failureObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main
        ) { [weak self] note in
            let message = (note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?.localizedDescription
            Task { @MainActor in self?.state = .failed(message ?? "playback_error".localized) }
        }

        player.replaceCurrentItem(with: item)
        player.play()
        startLoadTimeout()
    }

    func play() { player.play() }
    func pause() { player.pause() }

    /// Current playback position in seconds (0 if unknown / live).
    var currentSeconds: Double {
        let t = player.currentTime().seconds
        return t.isFinite ? t : 0
    }

    /// Seek to a position (used to resume Continue Watching).
    func seek(to seconds: Double) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    func teardown() {
        timeoutTask?.cancel()
        player.pause()
        player.replaceCurrentItem(with: nil)
        teardownObservers()
        state = .idle
        isLive = false
    }

    private func startLoadTimeout() {
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: self?.loadTimeout ?? 15_000_000_000)
            guard let self, !Task.isCancelled else { return }
            if case .playing = self.state { return }
            self.state = .failed("out_of_service".localized)
        }
    }

    private func teardownObservers() {
        statusObservation?.invalidate()
        statusObservation = nil
        if let failureObserver {
            NotificationCenter.default.removeObserver(failureObserver)
            self.failureObserver = nil
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AVPlayerEngine] audio session error: \(error.localizedDescription)")
        }
    }
}
