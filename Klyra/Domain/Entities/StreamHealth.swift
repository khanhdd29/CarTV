//
//  StreamHealth.swift
//  SwiftBase
//
//  Health of a stream link (spec §Driver 3 — Playlist Health). Local-only: the
//  app probes links on-device and caches the last-known state keyed by stream URL.
//

import Foundation

enum StreamStatus: Int, Sendable {
    case unknown = 0
    case online = 1
    case offline = 2
}
