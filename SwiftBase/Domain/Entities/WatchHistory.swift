//
//  WatchHistory.swift
//  SwiftBase
//
//  Domain entity for the Recents tab. Identity is `streamURL` (stable across
//  playlist re-parses, like Favourite). Capped to the most recent 100 locally.
//

import Foundation

struct WatchHistory: Identifiable, Codable, Hashable {
    var id: String { streamURL }

    let streamURL: String
    let name: String
    let logoURL: String?
    let groupTitle: String?
    let watchedAt: Date

    init(streamURL: String, name: String, logoURL: String?, groupTitle: String?, watchedAt: Date = Date()) {
        self.streamURL = streamURL
        self.name = name
        self.logoURL = logoURL
        self.groupTitle = groupTitle
        self.watchedAt = watchedAt
    }
}

extension WatchHistory {
    init(channel: Channel) {
        self.init(streamURL: channel.streamURL, name: channel.name,
                  logoURL: channel.logoURL, groupTitle: channel.groupTitle)
    }

    var asChannel: Channel {
        Channel(id: -1, playlistId: "", name: name, streamURL: streamURL,
                logoURL: logoURL, groupTitle: groupTitle, tvgId: nil)
    }
}
