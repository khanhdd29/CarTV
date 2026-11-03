//
//  Container+IPTV.swift
//  SwiftBase
//
//  Dependency inversion wiring (spec §7): view models resolve the *protocols*
//  `PlaylistRepository` / `UserDataRepository`. Swapping the local store for a
//  cloud-backed one later is a one-line change here, nothing else moves.
//

import Foundation
import Factory

extension Container {
    /// Single SQLite-backed store shared by both repositories.
    var iptvStore: Factory<IPTVStore> {
        Factory(self) {
            do { return try IPTVStore() }
            catch { fatalError("Failed to open IPTV store: \(error)") }
        }.singleton
    }

    var playlistRepository: Factory<PlaylistRepository> {
        Factory(self) { LocalPlaylistRepository(store: self.iptvStore()) }.singleton
    }

    var userDataRepository: Factory<UserDataRepository> {
        Factory(self) { LocalUserDataRepository(store: self.iptvStore()) }.singleton
    }

    var epgRepository: Factory<EPGRepository> {
        Factory(self) { LocalEPGRepository(store: self.iptvStore()) }.singleton
    }

    var healthRepository: Factory<HealthRepository> {
        Factory(self) { LocalHealthRepository(store: self.iptvStore()) }.singleton
    }

    /// Shared, observable stream-health cache for channel cards + the player.
    var healthCenter: Factory<HealthCenter> {
        Factory(self) { @MainActor in HealthCenter() }.singleton
    }

    /// Shared playback session (queue + engine) used by the Player screen.
    var playerController: Factory<PlayerController> {
        Factory(self) { @MainActor in PlayerController() }.singleton
    }
}
