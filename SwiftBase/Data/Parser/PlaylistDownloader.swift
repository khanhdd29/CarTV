//
//  PlaylistDownloader.swift
//  SwiftBase
//
//  Downloads a playlist to a temporary file (never into memory) so the parser
//  can stream it off disk. Caller owns the returned file and deletes it.
//

import Foundation

struct PlaylistDownloader {
    func download(_ url: URL) async throws -> URL {
        do {
            let (tempURL, response) = try await URLSession.shared.download(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                try? FileManager.default.removeItem(at: tempURL)
                throw AppError.network(underlying: "HTTP \(http.statusCode)")
            }
            // The system temp file is removed when this scope ends, so move it.
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("playlist-\(UUID().uuidString).m3u")
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tempURL, to: dest)
            return dest
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.network(underlying: error.localizedDescription)
        }
    }
}
