//
//  API.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import Foundation
import Alamofire

let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as! String
let pr = Bundle.main.object(forInfoDictionaryKey: "API_PROTOCOL") as! String
let host = Bundle.main.object(forInfoDictionaryKey: "API_HOST") as! String
let path = Bundle.main.object(forInfoDictionaryKey: "API_PATH") as! String

let baseAPIURL = "\(pr)://\(host)\(path)"

struct SteamGameResponse: Codable, Sendable {
    let data: [SteamGame]
}

enum APIError: Error {
    case badURL
    case invalidResponse
}

final class SteamAPI {
    var hasCache: Bool = false
    var progress: Double = 0
    
    private var cache: [String: [SteamGame]] = [:]
    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("SteamCache.plist")
    }

    private func loadCache() {
        do {
            let data = try Data(contentsOf: cacheURL)
            let decoded = try JSONDecoder().decode([String: [SteamGame]].self, from: data)
            self.cache = decoded
            self.hasCache = true
            print("Cache loaded")
        } catch {
            self.hasCache = false
            print("Cache is empty")
        }
    }
    
    init() {
        loadCache()
    }

    private func saveCache() {
        do {
            let encoded = try JSONEncoder().encode(self.cache)
            try encoded.write(to: self.cacheURL, options: [.atomic])
            self.hasCache = true
            print("Cache saved")
        } catch {
            print(error)
        }
    }
    func deleteCache() {
        try? FileManager.default.removeItem(at: cacheURL)
        self.cache.removeAll()
        self.hasCache = true
        print("Cache deleted")
    }
    func fetchGameInfo(appID: String) async throws -> [SteamGame]? {
        if let cached = cache[appID] {
//            print("Returning from cache for id \(appID)")
            return cached
        }
        
        let urlString = "\(baseAPIURL)?appid=\(appID)"
        let headers: HTTPHeaders = ["x-api-key": apiKey]

        do {
            let data = try await AF.request(urlString, method: .get, headers: headers)
                .validate(statusCode: 200..<300)
                .serializingData()
                .value
            
            let root = try JSONDecoder().decode(SteamGameResponse.self, from: data)
            
//            print("Decoded \(root.data.count) items for game \(appID)")
            cache[appID] = root.data
            saveCache()
            return root.data
        }
    }
    func fetchGamesInfo(appIDs: [String]) async throws -> [SteamGame] {
        var items: [SteamGame] = []
        let total = appIDs.count
        // Reset progress at start
        self.progress = 0

        for (index, appID) in appIDs.enumerated() {
            if let gameInfo = try await self.fetchGameInfo(appID: appID) {
                items.append(contentsOf: gameInfo)
            }
            // Update progress as percentage of total processed
            if total > 0 {
                let processed = index + 1
                let percent = (Double(processed) / Double(total)) * 100.0
                self.progress = percent
//                print(self.progress)
            }
        }
        // Ensure progress is 100% at completion when there were items to process
        if total > 0 {
            self.progress = 100
        }
        print(items.map(\.id))
        return items
    }
}

