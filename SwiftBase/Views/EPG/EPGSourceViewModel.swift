//
//  EPGSourceViewModel.swift
//  SwiftBase
//
//  Lets the user point the app at an XMLTV program-guide link (same idea as an
//  M3U link). Local-only: the guide is parsed + cached on-device, matched to
//  channels by `tvg-id`.
//

import Foundation
import Factory

@MainActor
final class EPGSourceViewModel: ObservableObject {
    @Injected(\.epgRepository) private var repo

    @Published var urlText = ""
    @Published var isLoading = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?
    @Published var hasSource = false

    func onAppear() {
        Task {
            let saved = await repo.sourceURL()
            urlText = saved ?? ""
            hasSource = !(saved ?? "").isEmpty
        }
    }

    func load() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = normalized(trimmed) else {
            errorMessage = "epg_invalid_url".localized
            return
        }
        urlText = url.absoluteString
        errorMessage = nil
        statusMessage = nil
        isLoading = true
        Task {
            do {
                let count = try await repo.refresh(url: url, onProgress: nil)
                statusMessage = String(format: "epg_loaded".localized, count)
                hasSource = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func clear() {
        Task {
            await repo.clear()
            urlText = ""
            hasSource = false
            statusMessage = nil
            errorMessage = nil
        }
    }

    /// Accept a bare host/path and default to https (matches the playlist flow).
    private func normalized(_ raw: String) -> URL? {
        guard !raw.isEmpty else { return nil }
        let withScheme = raw.contains("://") ? raw : "https://\(raw)"
        guard let url = URL(string: withScheme), url.host != nil else { return nil }
        return url
    }
}
