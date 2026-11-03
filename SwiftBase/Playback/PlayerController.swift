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
    @Injected(\.epgRepository) private var epgRepo: EPGRepository
    @Injected(\.healthCenter) private var healthCenter: HealthCenter
    @Injected(\.app) private var app: AppManager

    /// Primary engine (AVPlayer). The view reads `avEngine.player`.
    let avEngine = AVPlayerEngine()

    @Published private(set) var queue: [Channel] = []
    @Published private(set) var index = 0
    /// True while the fallback (VLCKit) engine is driving playback.
    @Published private(set) var usingFallback = false
    /// Now/next programme for the current channel (empty when no EPG match).
    @Published private(set) var nowNext = EPGNowNext(now: nil, next: nil)

    private var cancellables = Set<AnyCancellable>()
    private var triedFallbackForCurrent = false
    /// Links that have already failed this session — not retried by auto-failover.
    private var failedURLs = Set<String>()

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
                if case .playing = state {
                    // Resume to the saved position once the stream is ready, and
                    // record the link as healthy.
                    self.attemptResume()
                    if let url = self.current?.streamURL { self.healthCenter.markOnline(url) }
                }
                // On failure: try VLCKit (no-op if not installed); if nothing can
                // take over, mark the link dead and auto-failover to a backup.
                if case .failed = state, !self.usingFallback, !self.triedFallbackForCurrent {
                    self.tryFallback()
                    if !self.usingFallback { self.failover() }
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
        failedURLs.removeAll()
        queue = channels
        index = min(max(0, startIndex), channels.count - 1)
        playCurrent()
    }

    func startSingle(_ channel: Channel) { start([channel], at: 0) }

    func next() { guard hasNext else { return }; saveCurrentPosition(); index += 1; playCurrent() }
    func previous() { guard hasPrevious else { return }; saveCurrentPosition(); index -= 1; playCurrent() }
    func retry() {
        if let url = current?.streamURL { failedURLs.remove(url) }
        triedFallbackForCurrent = false; usingFallback = false; playCurrent()
    }

    // MARK: Auto-failover (Playlist Health, Driver 3)

    /// A dead link just surfaced: flag it and jump to a backup source — another
    /// channel with the same name that we haven't already failed on.
    private func failover() {
        guard let channel = current else { return }
        healthCenter.markOffline(channel.streamURL)
        failedURLs.insert(channel.streamURL)
        guard let alt = alternativeIndex(for: channel) else { return }
        index = alt
        playCurrent()
    }

    /// Index of an untried channel sharing this one's name (a mirror source).
    private func alternativeIndex(for channel: Channel) -> Int? {
        let name = channel.name.lowercased()
        return queue.firstIndex { $0.name.lowercased() == name && !failedURLs.contains($0.streamURL) }
    }

    func stop() {
        saveCurrentPosition()
        avEngine.teardown()
        teardownFallback()
        usingFallback = false
        nowNext = EPGNowNext(now: nil, next: nil)
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
        loadNowNext(for: channel)
    }

    /// Look up the current channel's program guide (matched by `tvg-id`).
    private func loadNowNext(for channel: Channel) {
        nowNext = EPGNowNext(now: nil, next: nil)
        let streamURL = channel.streamURL
        Task {
            let result = await epgRepo.nowNext(for: channel)
            // Guard against a late response after the user moved to another channel.
            guard self.current?.streamURL == streamURL else { return }
            self.nowNext = result
        }
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
