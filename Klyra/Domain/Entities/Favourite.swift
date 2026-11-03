//
//  Favourite.swift
//  SwiftBase
//
//  Domain entity — kept intentionally light so it can later sync to the cloud
//  (Firestore) without touching the domain (spec §8.1). Identity is `streamURL`
//  so a favourite survives re-parsing a playlist (local row ids change).
//

import Foundation

struct Favourite: Identifiable, Codable, Hashable {
    var id: String { streamURL }

    let streamURL: String
    let name: String
    let logoURL: String?
    let groupTitle: String?
    let addedAt: Date

    init(streamURL: String, name: String, logoURL: String?, groupTitle: String?, addedAt: Date = Date()) {
        self.streamURL = streamURL
        self.name = name
        self.logoURL = logoURL
        self.groupTitle = groupTitle
        self.addedAt = addedAt
    }
}

extension Favourite {
    /// Build a favourite snapshot from a channel.
    init(channel: Channel) {
        self.init(
            streamURL: channel.streamURL,
            name: channel.name,
            logoURL: channel.logoURL,
            groupTitle: channel.groupTitle
        )
    }

    /// Expose the favourite as a playable channel (negative id = not a DB row).
    var asChannel: Channel {
        Channel(
            id: -1,
            playlistId: "",
            name: name,
            streamURL: streamURL,
            logoURL: logoURL,
            groupTitle: groupTitle,
            tvgId: nil
        )
    }
}
