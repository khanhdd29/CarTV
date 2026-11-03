//
//  UserDataRepository.swift
//  SwiftBase
//
//  DOMAIN contract for *light* user state (favourites/history/settings). Today a
//  LocalUserDataRepository backs it; tomorrow a FirestoreUserDataRepository can
//  conform to the exact same protocol and sync — the domain never changes
//  (spec §8.1). The MVP slice implements favourites only; history/settings are
//  declared here as the forward-looking surface.
//

import Foundation

protocol UserDataRepository {
    func favourites() async throws -> [Favourite]
    func favouriteStreamURLs() async throws -> Set<String>
    func isFavourite(streamURL: String) async throws -> Bool
    func addFavourite(_ favourite: Favourite) async throws
    func removeFavourite(streamURL: String) async throws

    // MARK: Watch history (Recents) — capped to the latest 100 locally.
    func recents(limit: Int) async throws -> [WatchHistory]
    func recordWatch(_ item: WatchHistory) async throws
    func clearRecents() async throws

    // MARK: Resume (Continue Watching) — playback position per stream.
    func savePosition(streamURL: String, seconds: Double) async throws
    func position(streamURL: String) async throws -> Double
}
