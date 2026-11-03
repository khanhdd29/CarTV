//
//  AddPlaylistUseCase.swift
//  SwiftBase
//
//  Thin domain use case: validate the link, derive a sensible name, delegate to
//  the repository. Keeps URL validation out of the view models.
//

import Foundation

struct AddPlaylistUseCase {
    let repository: PlaylistRepository

    @discardableResult
    func callAsFunction(
        name rawName: String,
        urlString: String,
        onProgress: (@Sendable (Int) -> Void)? = nil
    ) async throws -> PlaylistRef {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme,
              scheme == "http" || scheme == "https", url.host != nil else {
            throw AppError.invalidURL
        }

        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = name.isEmpty ? (url.host ?? "Playlist") : name

        return try await repository.addPlaylist(name: resolvedName, url: url, onProgress: onProgress)
    }
}
