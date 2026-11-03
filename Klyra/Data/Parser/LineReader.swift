//
//  LineReader.swift
//  SwiftBase
//
//  Reads a (potentially large) file line by line in fixed-size chunks, so a
//  20MB+ M3U never gets loaded into RAM whole (spec §Driver 1, §5.7).
//

import Foundation

final class LineReader {
    private let handle: FileHandle
    private let chunkSize: Int
    private var buffer = Data()
    private var eof = false
    private let newline = UInt8(ascii: "\n")

    init(fileURL: URL, chunkSize: Int = 64 * 1024) throws {
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else {
            throw AppError.storage(underlying: "Cannot open parsed file")
        }
        self.handle = handle
        self.chunkSize = chunkSize
    }

    deinit { try? handle.close() }

    /// Returns the next line (without the trailing newline / carriage return),
    /// or `nil` at end of file.
    func next() -> String? {
        while true {
            if let range = buffer.firstRange(of: [newline]) {
                let lineData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
                buffer.removeSubrange(buffer.startIndex...range.lowerBound)
                return decode(lineData)
            }
            if eof {
                guard !buffer.isEmpty else { return nil }
                let lineData = buffer
                buffer.removeAll(keepingCapacity: false)
                return decode(lineData)
            }
            let chunk = handle.readData(ofLength: chunkSize)
            if chunk.isEmpty { eof = true } else { buffer.append(chunk) }
        }
    }

    private func decode(_ data: Data) -> String {
        var d = data
        if d.last == UInt8(ascii: "\r") { d.removeLast() }
        return String(decoding: d, as: UTF8.self)
    }
}
