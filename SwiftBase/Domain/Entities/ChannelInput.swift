//
//  ChannelInput.swift
//  SwiftBase
//
//  Domain-level channel payload for creating playlists that aren't parsed from
//  an M3U (a single pasted stream, or imported device videos). Keeps the Data
//  layer's `ParsedChannel` out of the domain contract.
//

import Foundation

struct ChannelInput: Hashable {
    let name: String
    let streamURL: String
    let logoURL: String?
    let groupTitle: String?

    init(name: String, streamURL: String, logoURL: String? = nil, groupTitle: String? = nil) {
        self.name = name
        self.streamURL = streamURL
        self.logoURL = logoURL
        self.groupTitle = groupTitle
    }
}
