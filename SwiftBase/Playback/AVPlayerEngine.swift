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
    /// Chosen playback speed (applies to on-demand content, not live).
    @Published private(set) var playbackRate: Float = 1.0
    /// Available subtitle / audio tracks of the current item (empty if none).
    @Published private(set) var subtitleOptions: [AVMediaSelectionOption] = []
    @Published private(set) var audioOptions: [AVMediaSelectionOption] = []
    private var subtitleGroup: AVMediaSelectionGroup?
    private var audioGroup: AVMediaSelectionGroup?

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
        if player.timeControlStatus == .playing { player.pause() } else { player.rate = playbackRate }
    }

    /// Set playback speed (e.g. 1.0, 1.5). Applies immediately if playing.
    func setRate(_ rate: Float) {
        playbackRate = rate
        if player.timeControlStatus != .paused { player.rate = rate }
    }

    /// Skip forward/back by `delta` seconds.
    func skip(_ delta: Double) {
        seek(to: max(0, currentSeconds + delta))
    }

    // MARK: Subtitles / audio tracks (media selection)

    private func loadMediaOptions(_ item: AVPlayerItem) {
        let asset = item.asset
        Task { [weak self] in
            let subs = try? await asset.loadMediaSelectionGroup(for: .legible)
            let auds = try? await asset.loadMediaSelectionGroup(for: .audible)
            await MainActor.run {
                guard let self, self.player.currentItem === item else { return }
                self.subtitleGroup = subs
                self.audioGroup = auds
                self.subtitleOptions = subs?.options ?? []
                self.audioOptions = auds?.options ?? []
            }
        }
    }

    func selectedSubtitle() -> AVMediaSelectionOption? { selected(in: subtitleGroup) }
    func selectedAudio() -> AVMediaSelectionOption? { selected(in: audioGroup) }

    private func selected(in group: AVMediaSelectionGroup?) -> AVMediaSelectionOption? {
        guard let group, let item = player.currentItem else { return nil }
        return item.currentMediaSelection.selectedMediaOption(in: group)
    }

    /// Pass `nil` to turn subtitles off.
    func selectSubtitle(_ option: AVMediaSelectionOption?) { select(option, in: subtitleGroup) }
    func selectAudio(_ option: AVMediaSelectionOption?) { select(option, in: audioGroup) }

    private func select(_ option: AVMediaSelectionOption?, in group: AVMediaSelectionGroup?) {
        guard let group, let item = player.currentItem else { return }
        item.select(option, in: group)
        objectWillChange.send()
    }

    func load(_ url: URL) {
        teardownObservers()
        timeoutTask?.cancel()
        state = .loading
        isLive = false
        subtitleOptions = []; audioOptions = []
        subtitleGroup = nil; audioGroup = nil

        let item = AVPlayerItem(url: url)
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.timeoutTask?.cancel()
                    self.isLive = item.duration.isIndefinite
                    self.state = .playing
                    self.loadMediaOptions(item)
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

    func play() { player.rate = playbackRate }
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
