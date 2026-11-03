//
//  EPGRepository.swift
//  SwiftBase
//
//  DOMAIN contract for the Electronic Program Guide. Local-only: the user
//  supplies an XMLTV link (like an M3U link); we parse + cache it on-device.
//

import Foundation

protocol EPGRepository {
    /// The configured XMLTV source URL, if any.
    func sourceURL() async -> String?

    /// Download + parse the XMLTV source, replacing the cached guide. Returns the
    /// number of programmes kept (a near-term window). `nil` url re-uses the saved one.
    @discardableResult
    func refresh(url: URL?, onProgress: (@Sendable (Int) -> Void)?) async throws -> Int

    /// Now + next programme for a channel. Matched by its `tvg-id`; when the
    /// channel object doesn't carry one (e.g. rebuilt from Favorites/Recents),
    /// the id is resolved from its stream URL.
    func nowNext(for channel: Channel) async -> EPGNowNext

    /// Remove the source + cached guide.
    func clear() async
}
