//
//  HealthRepository.swift
//  SwiftBase
//
//  DOMAIN contract for the Playlist Health engine (spec §Driver 3). Pure client:
//  probes happen on-device, results cached locally. No server, no reporting.
//

import Foundation

protocol HealthRepository {
    /// Last-known status for every stream URL we've probed.
    func cachedStatuses() async -> [String: StreamStatus]

    /// Probe each channel's link and cache the result. `onProgress(done, total)`
    /// fires as the sweep advances. Returns the online/offline tally.
    @discardableResult
    func probe(_ channels: [Channel],
               onProgress: (@Sendable (Int, Int) -> Void)?) async -> (online: Int, offline: Int)

    /// Probe every channel of one playlist (fetched from the local store).
    @discardableResult
    func probePlaylist(id: String,
                       onProgress: (@Sendable (Int, Int) -> Void)?) async -> (online: Int, offline: Int)

    /// Record a single link's status (e.g. playback failed → offline, or a
    /// stream that started playing → online).
    func record(streamURL: String, status: StreamStatus) async
}
