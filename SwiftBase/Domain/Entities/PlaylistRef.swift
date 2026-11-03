//
//  PlaylistRef.swift
//  SwiftBase
//
//  Domain entity — only the playlist *metadata + link* lives here. The heavy
//  channel list is reconstructed locally by re-parsing `sourceURL`, never stored
//  in the cloud (see spec §3, §8.3).
//

import Foundation

enum PlaylistType: String, Codable, Hashable {
    case m3u
    case xtream
    case server
    case stream   // a single pasted stream saved as a 1-channel playlist
    case device   // videos imported from the device's Photos library
}

struct PlaylistRef: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    let sourceURL: String
    let type: PlaylistType
    let addedAt: Date
    var channelCount: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        sourceURL: String,
        type: PlaylistType = .m3u,
        addedAt: Date = Date(),
        channelCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.sourceURL = sourceURL
        self.type = type
        self.addedAt = addedAt
        self.channelCount = channelCount
    }
}
