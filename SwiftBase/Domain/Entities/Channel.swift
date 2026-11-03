//
//  Channel.swift
//  SwiftBase
//
//  Domain entity — pure Swift, no persistence/SDK imports.
//

import Foundation

/// A single playable channel parsed from a playlist.
///
/// `id` is the local SQLite row id and is only stable within one parse of a
/// playlist. The *stable* identity used for favourites/history is `streamURL`.
struct Channel: Identifiable, Hashable {
    let id: Int64
    let playlistId: String
    let name: String
    let streamURL: String
    let logoURL: String?
    let groupTitle: String?
    let tvgId: String?

    var logoImageURL: URL? {
        guard let logoURL, !logoURL.isEmpty else { return nil }
        return URL(string: logoURL)
    }

    var streamingURL: URL? { URL(string: streamURL) }
}
