//
//  XMLTVParser.swift
//  SwiftBase
//
//  Streaming XMLTV parser (SAX via Foundation's XMLParser). To keep memory + the
//  cache small, only programmes inside a near-term window are kept (spec §Driver 5
//  — XMLTV files can be tens of MB). Handles plain `.xml`; `.xml.gz` should be
//  pointed at its uncompressed URL for now.
//

import Foundation

struct ParsedProgramme {
    let channelId: String
    let start: Date
    let stop: Date
    let title: String
}

final class XMLTVParser: NSObject, XMLParserDelegate {
    private var programmes: [ParsedProgramme] = []

    // Window kept: a little in the past (so "now" resolves) through +48h.
    private let windowStart = Date().addingTimeInterval(-6 * 3600)
    private let windowEnd = Date().addingTimeInterval(48 * 3600)

    private var curChannel: String?
    private var curStart: Date?
    private var curStop: Date?
    private var curTitle = ""
    private var inTitle = false

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMddHHmmss Z"
        return f
    }()

    func parse(fileURL: URL) throws -> [ParsedProgramme] {
        programmes = []
        guard let parser = XMLParser(contentsOf: fileURL) else {
            throw AppError.storage(underlying: "Cannot open EPG file")
        }
        parser.delegate = self
        guard parser.parse() else {
            throw AppError.network(underlying: parser.parserError?.localizedDescription ?? "XMLTV parse error")
        }
        return programmes
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes: [String: String] = [:]) {
        switch elementName {
        case "programme":
            curChannel = attributes["channel"]
            curStart = date(attributes["start"])
            curStop = date(attributes["stop"])
            curTitle = ""
        case "title":
            inTitle = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inTitle { curTitle += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        switch elementName {
        case "title":
            inTitle = false
        case "programme":
            if let channel = curChannel, let start = curStart, let stop = curStop,
               !curTitle.isEmpty, stop >= windowStart, start <= windowEnd {
                programmes.append(ParsedProgramme(
                    channelId: channel, start: start, stop: stop,
                    title: curTitle.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
            curChannel = nil; curStart = nil; curStop = nil; curTitle = ""
        default:
            break
        }
    }

    /// Parse an XMLTV timestamp: "20240101120000 +0000" or "20240101120000".
    private func date(_ raw: String?) -> Date? {
        guard var s = raw?.trimmingCharacters(in: .whitespaces), !s.isEmpty else { return nil }
        if !s.contains(" ") { s += " +0000" }
        return formatter.date(from: s)
    }
}
