//
//  LocalUserDataRepository.swift
//  SwiftBase
//
//  DATA layer — favourites stored locally for the MVP slice. When cloud sync
//  lands (spec v1), a FirestoreUserDataRepository conforms to the same
//  `UserDataRepository` and the swap is one line in the DI container (§8.2).
//

import Foundation

final class LocalUserDataRepository: UserDataRepository {
    private let store: IPTVStore

    init(store: IPTVStore) {
        self.store = store
    }

    func favourites() async throws -> [Favourite] { try await store.favourites() }
    func favouriteStreamURLs() async throws -> Set<String> { try await store.favouriteStreamURLs() }
    func isFavourite(streamURL: String) async throws -> Bool { try await store.isFavourite(streamURL: streamURL) }
    func addFavourite(_ favourite: Favourite) async throws { try await store.addFavourite(favourite) }
    func removeFavourite(streamURL: String) async throws { try await store.removeFavourite(streamURL: streamURL) }

    func recents(limit: Int) async throws -> [WatchHistory] { try await store.recents(limit: limit) }
    func recordWatch(_ item: WatchHistory) async throws { try await store.recordWatch(item) }
    func clearRecents() async throws { try await store.clearRecents() }

    func savePosition(streamURL: String, seconds: Double) async throws {
        try await store.savePosition(streamURL: streamURL, seconds: seconds)
    }
    func position(streamURL: String) async throws -> Double {
        try await store.position(streamURL: streamURL)
    }
}
