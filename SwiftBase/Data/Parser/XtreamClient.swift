//
//  XtreamClient.swift
//  SwiftBase
//
//  Minimal Xtream Codes client: authenticates and loads LIVE categories +
//  streams via `player_api.php`, mapping them to domain `ChannelInput`s. Stream
//  URLs are built in HLS (`.m3u8`) form so AVPlayer can play them (VLCKit
//  fallback covers raw `.ts`-only servers).
//

import Foundation

struct XtreamCredentials {
    let base: URL          // e.g. http://host:port
    let username: String
    let password: String
}

enum XtreamError: LocalizedError {
    case auth
    case server(String)

    var errorDescription: String? {
        switch self {
        case .auth:              return "xtream_auth_failed".localized
        case .server(let msg):   return msg
        }
    }
}

struct XtreamClient {
    /// Authenticate + fetch all live channels for the account.
    func fetchLiveChannels(
        _ cred: XtreamCredentials,
        onProgress: (@Sendable (Int) -> Void)? = nil
    ) async throws -> [ChannelInput] {
        // 1. Auth
        let info = try await getJSON(cred, action: nil)
        if let dict = info as? [String: Any],
           let user = dict["user_info"] as? [String: Any],
           Self.string(user["auth"]) == "0" {
            throw XtreamError.auth
        }

        // 2. Categories → id→name
        var categoryName: [String: String] = [:]
        if let cats = try await getJSON(cred, action: "get_live_categories") as? [[String: Any]] {
            for c in cats {
                if let id = Self.string(c["category_id"]), let name = Self.string(c["category_name"]) {
                    categoryName[id] = name
                }
            }
        }

        // 3. Live streams
        guard let streams = try await getJSON(cred, action: "get_live_streams") as? [[String: Any]] else {
            return []
        }

        var inputs: [ChannelInput] = []
        inputs.reserveCapacity(streams.count)
        let b = cred.base.absoluteString.hasSuffix("/")
            ? String(cred.base.absoluteString.dropLast()) : cred.base.absoluteString
        for s in streams {
            guard let sid = Self.string(s["stream_id"]) else { continue }
            let name = Self.string(s["name"]) ?? "Channel \(sid)"
            let icon = Self.string(s["stream_icon"])
            let group = Self.string(s["category_id"]).flatMap { categoryName[$0] }
            let url = "\(b)/live/\(cred.username)/\(cred.password)/\(sid).m3u8"
            inputs.append(ChannelInput(name: name, streamURL: url,
                                       logoURL: (icon?.isEmpty == false) ? icon : nil,
                                       groupTitle: group))
            onProgress?(inputs.count)
        }
        return inputs
    }

    // MARK: Request

    private func getJSON(_ cred: XtreamCredentials, action: String?) async throws -> Any {
        var comps = URLComponents(url: cred.base.appendingPathComponent("player_api.php"),
                                  resolvingAgainstBaseURL: false)
        var items = [
            URLQueryItem(name: "username", value: cred.username),
            URLQueryItem(name: "password", value: cred.password)
        ]
        if let action { items.append(URLQueryItem(name: "action", value: action)) }
        comps?.queryItems = items
        guard let url = comps?.url else { throw XtreamError.server("invalid_url".localized) }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw XtreamError.server("HTTP \(http.statusCode)")
            }
            return try JSONSerialization.jsonObject(with: data)
        } catch let error as XtreamError {
            throw error
        } catch {
            throw XtreamError.server(error.localizedDescription)
        }
    }

    /// Xtream fields come back as String or Int — coerce to String.
    private static func string(_ any: Any?) -> String? {
        switch any {
        case let s as String: return s
        case let i as Int:    return String(i)
        case let n as NSNumber: return n.stringValue
        default: return nil
        }
    }
}
