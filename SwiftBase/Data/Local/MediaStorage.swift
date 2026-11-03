//
//  MediaStorage.swift
//  SwiftBase
//
//  Copies device-picked videos into the app's own storage so they remain
//  playable later (the Photos picker's temp URLs don't persist).
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

enum MediaStorage {
    static func directory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let dir = base.appendingPathComponent("DeviceVideos", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Copy a source file into app storage, returning the persistent URL.
    static func copyIntoStorage(_ source: URL) throws -> URL {
        let dir = try directory()
        let ext = source.pathExtension.isEmpty ? "mov" : source.pathExtension
        let dest = dir.appendingPathComponent("\(UUID().uuidString).\(ext)")
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.copyItem(at: source, to: dest)
        return dest
    }
}

/// `Transferable` wrapper so `PhotosPicker` hands us a file we can copy and keep.
struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copied = try MediaStorage.copyIntoStorage(received.file)
            return PickedMovie(url: copied)
        }
    }
}
