//
//  AddPlaylistViewModel.swift
//  SwiftBase
//
//  Four ways to add media (matching the reference apps): a remote M3U URL, a
//  local .m3u file, a single pasted stream (play now or save), and videos from
//  the device's Photos library. All persistence goes through the domain
//  `PlaylistRepository`; playback through the shared `PlayerController`.
//

import Foundation
import SwiftUI
import PhotosUI
import Factory

@MainActor
final class AddPlaylistViewModel: ObservableObject {
    enum Mode: CaseIterable, Identifiable {
        // Ordered most-common first; Xtream (niche) last.
        case url, file, stream, device, xtream
        var id: Self { self }
        var title: String {
            switch self {
            case .url:    return "source_url".localized
            case .xtream: return "source_xtream".localized
            case .file:   return "source_file".localized
            case .stream: return "source_stream".localized
            case .device: return "source_device".localized
            }
        }
    }

    @Injected(\.playlistRepository) private var playlistRepo: PlaylistRepository
    @Injected(\.playerController) private var player: PlayerController
    @Injected(\.app) private var app: AppManager

    @Published var mode: Mode = .url
    @Published var urlText = ""
    @Published var nameText = ""
    @Published var streamText = ""
    @Published var streamNameText = ""
    @Published var xtreamURL = ""
    @Published var xtreamUser = ""
    @Published var xtreamPass = ""
    @Published var isWorking = false
    @Published var importedCount = 0
    @Published var errorMessage: String?

    private var trimmedURL: String { urlText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedStream: String { streamText.trimmingCharacters(in: .whitespacesAndNewlines) }

    var canSubmitURL: Bool { !trimmedURL.isEmpty && !isWorking }
    var canSubmitStream: Bool { !trimmedStream.isEmpty && !isWorking }
    var canSubmitXtream: Bool {
        !xtreamURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !xtreamUser.isEmpty && !xtreamPass.isEmpty && !isWorking
    }

    // MARK: Xtream Codes

    func addXtream() {
        guard canSubmitXtream else { return }
        let urlStr = xtreamURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: urlStr), let scheme = url.scheme,
              scheme == "http" || scheme == "https", url.host != nil else {
            errorMessage = AppError.invalidURL.localizedDescription
            return
        }
        begin()
        let user = xtreamUser, pass = xtreamPass
        let name = "Xtream · \(url.host ?? "server")"
        Task {
            do {
                try await playlistRepo.addXtreamPlaylist(name: name, serverURL: url, username: user, password: pass) { [weak self] count in
                    Task { @MainActor in self?.importedCount = count }
                }
                finishSuccess()
            } catch { fail(error) }
        }
    }

    // MARK: URL

    func addURL() {
        guard canSubmitURL else { return }
        begin()
        let useCase = AddPlaylistUseCase(repository: playlistRepo)
        let name = nameText, url = urlText
        Task {
            do {
                try await useCase(name: name, urlString: url) { [weak self] count in
                    Task { @MainActor in self?.importedCount = count }
                }
                finishSuccess()
            } catch { fail(error) }
        }
    }

    // MARK: File

    func importFile(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let urls):
            guard let fileURL = urls.first else { return }
            begin()
            let name = nameText.isEmpty ? fileURL.deletingPathExtension().lastPathComponent : nameText
            Task {
                do {
                    try await playlistRepo.importPlaylist(name: name, fileURL: fileURL) { [weak self] count in
                        Task { @MainActor in self?.importedCount = count }
                    }
                    finishSuccess()
                } catch { fail(error) }
            }
        }
    }

    // MARK: Stream (single URL)

    func playStreamNow() {
        guard !trimmedStream.isEmpty else { return }
        let channel = Channel(id: -1, playlistId: "", name: streamDisplayName,
                              streamURL: trimmedStream, logoURL: nil, groupTitle: nil, tvgId: nil)
        player.startSingle(channel)
        app.navi.push(.player, type: .fullScreenCover)
    }

    func saveStream() {
        guard canSubmitStream else { return }
        begin()
        let input = ChannelInput(name: streamDisplayName, streamURL: trimmedStream)
        let name = streamDisplayName
        Task {
            do {
                try await playlistRepo.createManualPlaylist(name: name, type: .stream, channels: [input])
                finishSuccess()
            } catch { fail(error) }
        }
    }

    private var streamDisplayName: String {
        if !streamNameText.trimmingCharacters(in: .whitespaces).isEmpty { return streamNameText }
        return URL(string: trimmedStream)?.host ?? "Stream"
    }

    // MARK: Device videos

    func importVideos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        begin()
        Task {
            var inputs: [ChannelInput] = []
            for (i, item) in items.enumerated() {
                if let movie = try? await item.loadTransferable(type: PickedMovie.self) {
                    let name = String(format: "video_number".localized, i + 1)
                    inputs.append(ChannelInput(name: name, streamURL: movie.url.absoluteString,
                                               groupTitle: "source_device".localized))
                    importedCount = inputs.count
                }
            }
            guard !inputs.isEmpty else { fail(AppError.emptyPlaylist); return }
            do {
                let name = nameText.isEmpty ? "source_device".localized : nameText
                try await playlistRepo.createManualPlaylist(name: name, type: .device, channels: inputs)
                finishSuccess()
            } catch { fail(error) }
        }
    }

    // MARK: Helpers

    private func begin() { isWorking = true; importedCount = 0; errorMessage = nil }
    private func finishSuccess() { isWorking = false; app.bumpData(); app.navi.pop() }
    private func fail(_ error: Error) { isWorking = false; errorMessage = error.localizedDescription }

    func cancel() { app.navi.pop() }
}
