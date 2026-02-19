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
let pathm = Bundle.main.object(forInfoDictionaryKey: "API_PATH_M") as! String

let baseAPIURL = "\(pr)://\(host)\(path)"
let baseAPIMURL = "\(pr)://\(host)\(pathm)"

struct SteamGameResponse: Codable, Sendable {
    let data: [SteamGame]
}

struct SteamGameResponseArray: Codable, Sendable {
    let data: [SteamGame]
}

enum APIError: Error {
    case badURL
    case invalidResponse
}

final class SteamAPI {
    var hasCache: Bool = false
    var progress: Double = 0
    private var cacheBlacklist: [String] = blacklist
    private var cache: [String: [SteamGame]] = [:]
    private var cacheIDS: [String] {
        if cache.count < 1 {
            return []
        }
        return cache.map { String($0.key) }
    }
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
            console.warn("Cache loaded")
        } catch {
            self.hasCache = false
            console.warn("Cache is empty")
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
            console.warn("Cache saved")
        } catch {
            console.error(error.localizedDescription)
        }
    }
    func deleteCache() {
        try? FileManager.default.removeItem(at: cacheURL)
        self.cache.removeAll()
        self.hasCache = true
        console.warn("Cache deleted")
    }
    func fetchGameInfo(appID: String) async throws -> [SteamGame]? {
        if self.cacheBlacklist.contains(appID) {
            return nil
        }
        if let cached = cache[appID] {
//            console.warn("Returning from cache for id \(appID)")
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
            
//            console.warn("Decoded \(root.data.count) items for game \(appID)")
            cache[appID] = root.data
            saveCache()
            return root.data
        }
    }
    func fetchGamesInfo(appIDs: [String], setProgress: @escaping (Double) -> Void = { _ in }) async throws -> [SteamGame] {
        var items: [SteamGame] = []
        let total = appIDs.count
        // Reset progress at start
        self.progress = 0
        setProgress(self.progress)
        
        for (index, appID) in appIDs.enumerated() {
            do {
                if let gameInfo = try await self.fetchGameInfo(appID: appID) {
                    items.append(contentsOf: gameInfo)
                }
            } catch {
                console.warn(error.localizedDescription)
            }
            // Update progress as percentage of total processed
            if total > 0 {
                let processed = index + 1
                let percent = (Double(processed) / Double(total)) * 100.0
                self.progress = percent
                setProgress(self.progress)
//                console.warn(self.progress)
            }
        }
        // Ensure progress is 100% at completion when there were items to process
        if total > 0 {
            self.progress = 100
            setProgress(self.progress)
        }
        console.warn("\(items.map(\.id))")
        return items
    }
    func fetchGameInfoArray(appIDs: [String], setProgress: @escaping (Double) -> Void = { _ in }) async throws -> [SteamGame] {
        console.log("requesting \(appIDs.count.description) games")
        let headers: HTTPHeaders = ["x-api-key": apiKey]
        var items: [SteamGame] = []
        let uncached: [String] = appIDs.filter { id in
            // Skip blacklisted IDs
            guard cacheBlacklist.contains(id) == false else { return false }
            // Only include IDs that are not present in the cache
            return cache[id] == nil
        }
        let cached = cache.filter { appIDs.contains($0.key) }

        console.warn("cache size: \(cache.count.description)")
        console.warn("uncached size: \(uncached.count.description)")
        
        if(uncached.count < 1) {
            console.warn("returning cached")
            return cached.map { $0.value[0] }
        }
        
        items.append(contentsOf: cached.map { $0.value[0] }) // start to populate with all cached games
        console.log("populating with cached data items: \(cached.count)")
        
        let urlString = "\(baseAPIMURL)?appids=\(uncached.joined(separator: ","))" //just request uncached ids
        console.log("requesting new items: [\(uncached.joined(separator: ","))]")
        
        do {
            let data = try await AF.request(urlString, method: .get, headers: headers)
                .validate(statusCode: 200..<300)
                .serializingData()
                .value
            let root = try JSONDecoder().decode(SteamGameResponse.self, from: data)
            items.append(contentsOf: root.data) // append the remaining reqested from the api
            root.data.forEach { cache[String($0.id)] = [$0] } //cache the new games that were fetched
            console.log("caching new items: \(root.data.count)")
            saveCache()
            setProgress(100)
            return items
        } catch {
            console.error("fetchGameInfoArray failed: \(error.localizedDescription)")
        }
        return []
    }
}

