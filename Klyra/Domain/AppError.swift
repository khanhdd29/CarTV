//
//  AppError.swift
//  SwiftBase
//
//  Domain-level errors surfaced to the presentation layer.
//

import Foundation

enum AppError: LocalizedError {
    case invalidURL
    case emptyPlaylist
    case network(underlying: String)
    case storage(underlying: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "invalid_url".localized
        case .emptyPlaylist:         return "empty_playlist".localized
        case .network(let message):  return message
        case .storage(let message):  return message
        }
    }
}
