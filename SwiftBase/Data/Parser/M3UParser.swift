//
//  M3UParser.swift
//  SwiftBase
//
//  Streaming M3U/M3U8 parser. Consumes a file line by line and flushes parsed
//  channels in batches via an async callback, so the persistence layer can
//  insert each batch and free it — memory stays bounded regardless of playlist
//  size (spec §Driver 1).
//
//  Grammar handled:
//    #EXTM3U
//    #EXTINF:-1 tvg-id="..." tvg-logo="..." group-title="News",Display Name
//    #EXTGRP:News           (optional group marker for the next entry)
//    http://host/stream     (the URL line following an #EXTINF)
//

import Foundation

struct M3UParser {
    /// Attribute scanner compiled once: matches key="value" pairs.
    private static let attrRegex = try? NSRegularExpression(pattern: "([a-zA-Z0-9_-]+)=\"([^\"]*)\"")

    /// Parse `fileURL`, delivering channels in batches of `batchSize`.
    func parse(
        fileURL: URL,
        batchSize: Int = 1_000,
        onBatch: (@Sendable ([ParsedChannel]) async throws -> Void)
    ) async throws {
        let reader = try LineReader(fileURL: fileURL)

        var batch: [ParsedChannel] = []
        batch.reserveCapacity(batchSize)

        var pendingName: String?
        var pendingLogo: String?
        var pendingGroup: String?
        var pendingTvgId: String?
        var extGroup: String?

        func flush() async throws {
            guard !batch.isEmpty else { return }
            try await onBatch(batch)
            batch.removeAll(keepingCapacity: true)
        }

        while let raw = reader.next() {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            if line.hasPrefix("#EXTINF") {
                let (attrs, name) = Self.splitExtinf(line)
                let dict = Self.attributes(in: attrs)
                pendingName = name.isEmpty ? (dict["tvg-name"] ?? "") : name
                pendingLogo = dict["tvg-logo"]
                pendingGroup = dict["group-title"]
                pendingTvgId = dict["tvg-id"]
            } else if line.hasPrefix("#EXTGRP:") {
                extGroup = String(line.dropFirst("#EXTGRP:".count)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("#") {
                continue // #EXTM3U, #EXTVLCOPT, comments, etc.
            } else {
                // A URL line. Pair it with the pending #EXTINF (if any).
                let name = pendingName?.isEmpty == false ? pendingName! : line
                // group-title can list several categories joined by ';'
                // (e.g. "Culture;Entertainment"). Keep the first as the group.
                let rawGroup = pendingGroup ?? extGroup
                let group = rawGroup?
                    .split(separator: ";").first
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                batch.append(ParsedChannel(
                    name: name,
                    streamURL: line,
                    logoURL: pendingLogo?.isEmpty == true ? nil : pendingLogo,
                    groupTitle: (group?.isEmpty == false) ? group : nil,
                    tvgId: pendingTvgId?.isEmpty == true ? nil : pendingTvgId
                ))
                pendingName = nil; pendingLogo = nil; pendingGroup = nil; pendingTvgId = nil; extGroup = nil

                if batch.count >= batchSize { try await flush() }
            }
        }
        try await flush()
    }

    /// Split an `#EXTINF:` line into (attributes, displayName) at the first comma
    /// that is NOT inside a quoted value (group titles can contain commas).
    static func splitExtinf(_ line: String) -> (attrs: String, name: String) {
        let content = String(line.dropFirst("#EXTINF:".count))
        var inQuotes = false
        var splitIndex: String.Index?
        var i = content.startIndex
        while i < content.endIndex {
            let c = content[i]
            if c == "\"" { inQuotes.toggle() }
            else if c == "," && !inQuotes { splitIndex = i; break }
            i = content.index(after: i)
        }
        guard let splitIndex else { return (content, "") }
        let attrs = String(content[content.startIndex..<splitIndex])
        let name = String(content[content.index(after: splitIndex)...]).trimmingCharacters(in: .whitespaces)
        return (attrs, name)
    }

    static func attributes(in attrs: String) -> [String: String] {
        guard let regex = attrRegex else { return [:] }
        let range = NSRange(attrs.startIndex..<attrs.endIndex, in: attrs)
        var dict: [String: String] = [:]
        regex.enumerateMatches(in: attrs, range: range) { match, _, _ in
            guard let match,
                  let keyRange = Range(match.range(at: 1), in: attrs),
                  let valueRange = Range(match.range(at: 2), in: attrs) else { return }
            dict[String(attrs[keyRange]).lowercased()] = String(attrs[valueRange])
        }
        return dict
    }
}
