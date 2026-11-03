//
//  PlayerController.swift
//  SwiftBase
//
//  Shared, app-wide playback session (one instance via Factory). Holds the
//  channel queue so the player can go next/previous, records watch history
//  (Recents), mirrors the engine's state for the view, and — when the optional
//  VLCKit package is present — falls back to VLC if AVPlayer can't play a stream.
//

import Foundation
import Combine
import Factory

@MainActor
final class PlayerController: ObservableObject {
    @Injected(\.userDataRepository) private var userRepo: UserDataRepository
    @Injected(\.app) private var app: AppManager

    /// Primary engine (AVPlayer). The view reads `avEngine.player`.
    let avEngine = AVPlayerEngine()

    @Published private(set) var queue: [Channel] = []
    @Published private(set) var index = 0
    /// True while the fallback (VLCKit) engine is driving playback.
    @Published private(set) var usingFallback = false

    private var cancellables = Set<AnyCancellable>()
    private var triedFallbackForCurrent = false

    // Resume (Continue Watching) state for the current channel.
    private var resumeTarget: Double = 0
    private var didSeekForCurrent = false

    init() {
        // Re-publish engine changes so views observing the controller update.
        avEngine.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        avEngine.$state
            .sink { [weak self] state in
                guard let self else { return }
                // Resume to the saved position once the stream is ready.
                if case .playing = state { self.attemptResume() }
                // Auto-fallback to VLCKit when AVPlayer fails (no-op if not installed).
                if case .failed = state, !self.usingFallback, !self.triedFallbackForCurrent {
                    self.tryFallback()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Derived

    var current: Channel? { queue.indices.contains(index) ? queue[index] : nil }
    var hasNext: Bool { index < queue.count - 1 }
    var hasPrevious: Bool { index > 0 }
    var isLive: Bool { avEngine.isLive }
    var state: PlaybackState { avEngine.state }

    // MARK: Control

    /// Begin a session with a queue (e.g. a channel list) starting at `startIndex`.
    func start(_ channels: [Channel], at startIndex: Int) {
        guard !channels.isEmpty else { return }
        queue = channels
        index = min(max(0, startIndex), channels.count - 1)
        playCurrent()
    }

    func startSingle(_ channel: Channel) { start([channel], at: 0) }

    func next() { guard hasNext else { return }; saveCurrentPosition(); index += 1; playCurrent() }
    func previous() { guard hasPrevious else { return }; saveCurrentPosition(); index -= 1; playCurrent() }
    func retry() { triedFallbackForCurrent = false; usingFallback = false; playCurrent() }

    func stop() {
        saveCurrentPosition()
        avEngine.teardown()
        teardownFallback()
        usingFallback = false
        queue = []
        index = 0
    }

    private func playCurrent() {
        guard let channel = current, let url = channel.streamingURL else { return }
        triedFallbackForCurrent = false
        usingFallback = false
        didSeekForCurrent = false
        resumeTarget = 0
        teardownFallback()
        avEngine.load(url)
        recordWatch(channel)
        loadResumeTarget(for: channel)
    }

    private func recordWatch(_ channel: Channel) {
        let item = WatchHistory(channel: channel)
        Task { try? await userRepo.recordWatch(item); app.bumpData() }
    }

    // MARK: Resume (Continue Watching)

    /// Fetch the saved position for a channel; apply it if already playing.
    private func loadResumeTarget(for channel: Channel) {
        let url = channel.streamURL
        Task {
            let pos = (try? await userRepo.position(streamURL: url)) ?? 0
            self.resumeTarget = pos
            self.attemptResume()
        }
    }

    /// Seek to the saved position once the stream is ready (skip live streams).
    private func attemptResume() {
        guard !didSeekForCurrent, !usingFallback, resumeTarget > 5, !avEngine.isLive else { return }
        guard case .playing = avEngine.state else { return }
        avEngine.seek(to: resumeTarget)
        didSeekForCurrent = true
    }

    /// Persist the current position so playback resumes next time (skip live).
    private func saveCurrentPosition() {
        guard let channel = current, !avEngine.isLive else { return }
        let pos = avEngine.currentSeconds
        guard pos > 5 else { return }
        let url = channel.streamURL
        Task { try? await userRepo.savePosition(streamURL: url, seconds: pos) }
    }

    // MARK: VLCKit fallback (active only when the MobileVLCKit package is linked)

    #if canImport(MobileVLCKit)
    let vlcEngine = VLCPlayerEngine()

    private func tryFallback() {
        triedFallbackForCurrent = true
        guard let url = current?.streamingURL else { return }
        usingFallback = true
        avEngine.pause()
        vlcEngine.load(url)
    }

    private func teardownFallback() { vlcEngine.stop() }
    #else
    /// No VLCKit linked → nothing to fall back to; the AVPlayer error stands.
    private func tryFallback() { triedFallbackForCurrent = true }
    private func teardownFallback() {}
    #endif
}
