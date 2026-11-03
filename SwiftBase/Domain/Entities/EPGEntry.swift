//
//  EPGEntry.swift
//  SwiftBase
//
//  Domain entity for a single programme in the guide (EPG). Matched to channels
//  by `tvg-id` (spec §Driver 5).
//

import Foundation

struct EPGEntry: Hashable {
    let title: String
    let start: Date
    let stop: Date

    /// Progress 0…1 through the programme at `date` (for a "now playing" bar).
    func progress(at date: Date = Date()) -> Double {
        let total = stop.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(max(date.timeIntervalSince(start) / total, 0), 1)
    }
}

/// Now + next programmes for a channel.
struct EPGNowNext: Hashable {
    let now: EPGEntry?
    let next: EPGEntry?
}
