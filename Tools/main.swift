//
//  main.swift
//  Tools
//
//  Created by Apollo Zhu on 9/10/19.
//  Copyright © 2018-2022 Dynamic Dark Mode. All rights reserved.
//

import Foundation

import XMLCoder

let releasesURL = "https://github.com/wulinan123/Dynamic-Dark-Mode/releases.atom"

struct Feed: Codable {
    struct Entry: Codable {
        let id: String
        let updated: Date
        let title: String
        let content: String
    }
    let entry: [Entry]
}

let dateFormatter = DateFormatter()
dateFormatter.locale = Locale(identifier: "en_US_POSIX")
dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss ZZ"

enum AppcastToolError: LocalizedError {
    case invalidReleasesURL
    case requestFailed(Error)
    case missingData
    case noEntries
    case invalidReleaseID(String)

    var errorDescription: String? {
        switch self {
        case .invalidReleasesURL:
            return "Invalid releases feed URL."
        case .requestFailed(let error):
            return error.localizedDescription
        case .missingData:
            return "The releases feed response did not contain data."
        case .noEntries:
            return "The releases feed did not contain any entries."
        case .invalidReleaseID(let id):
            return "Could not derive a version from release id: \(id)"
        }
    }
}

extension Feed.Entry {
    func appcastItem() throws -> String {
        guard let lastSlashIndex = id.lastIndex(of: "/") else {
            throw AppcastToolError.invalidReleaseID(id)
        }
        let version = id[id.index(after: lastSlashIndex)...]
        guard !version.isEmpty else {
            throw AppcastToolError.invalidReleaseID(id)
        }
        return """
        <item>
        <title>\(title)</title>
        <pubDate>\(dateFormatter.string(from: updated))</pubDate>
        <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
        <description><![CDATA[\(content)]]></description>
        <enclosure url="https://github.com/wulinan123/Dynamic-Dark-Mode/releases/download/\(version)/Dynamic_Dark_Mode-\(version).zip" sparkle:version="\(version)" type="application/octet-stream"/>
        </item>
        """
    }
}

func fail(_ error: Error) -> Never {
    fputs("error: \(error.localizedDescription)\n", stderr)
    exit(EXIT_FAILURE)
}

guard let url = URL(string: releasesURL) else {
    fail(AppcastToolError.invalidReleasesURL)
}

URLSession.shared.dataTask(with: url) { data, _, error in
    if let error {
        fail(AppcastToolError.requestFailed(error))
    }
    guard let data = data else {
        fail(AppcastToolError.missingData)
    }
    do {
        let decoder = XMLDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let feed = try decoder.decode(Feed.self, from: data)
        guard let entry = feed.entry.first else {
            throw AppcastToolError.noEntries
        }
        print(try entry.appcastItem())
    } catch {
        fail(error)
    }
    /*
    // I don't know how to do the checksum, so commented out...

    let items = feed.entry.enumerated().reduce("") { (result, item) -> String in
        return result + item.1.appcastItem() + "\n" // sparkleVersion: feed.entry.count - item.0 - 1
    }
    let string = """
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
    <channel>
    <title>Dynamic Dark Mode</title>
    <link>
    https://wulinan123.github.io/Dynamic-Dark-Mode/appcast.xml
    </link>
    <language>en</language>
    \(items)
    </channel>
    </rss>
    """
    try string.write(toFile: "appcast.xml", atomically: true, encoding: .utf8)
    print(FileManager.default.currentDirectoryPath)
    */
    exit(EXIT_SUCCESS)
}.resume()

RunLoop.main.run()
