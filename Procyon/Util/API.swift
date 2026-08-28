//
//  API.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import Foundation
import Alamofire

var apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as! String
let pr = Bundle.main.object(forInfoDictionaryKey: "API_PROTOCOL") as! String
let host = Bundle.main.object(forInfoDictionaryKey: "API_HOST") as! String
let path = Bundle.main.object(forInfoDictionaryKey: "API_PATH") as! String
let pathm = Bundle.main.object(forInfoDictionaryKey: "API_PATH_M") as! String
let pathCustom = Bundle.main.object(forInfoDictionaryKey: "API_PATH_CUSTOM") as! String

let baseAPIURL = "\(pr)://\(host)\(path)"
let baseAPIMURL = "\(pr)://\(host)\(pathm)"

struct SteamGameResponse: Codable, Sendable {
    let data: [SteamGame]
}

struct SteamOwnedGamesResponse: Codable, Sendable {
    let response: SteamOwnedGames
}

struct SteamOwnedGamesResponseData: Codable, Sendable {
    let data: SteamOwnedGamesResponse
}

struct SteamGameResponseArray: Codable, Sendable {
    let data: [SteamGame]
}

enum APIError: Error {
    case badURL
    case invalidResponse
}

final class SteamAPI {
    var progress: Double = 0
    private var cacheBlacklist: [String] = BLACKLIST
    private var cacheProfileData: UserInfo? = nil
    private var cache: [String: SteamGame] = [:]
    private var autoConfigCache: [String: GameOptionsData] = [:]
    private var cacheOwnedGamesIDs: [String] = []
    private let apiKey: String = Secrets.apiKey
    private var cacheBlacklistURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("ProcyonSteamCacheBlacklist.plist")
    }
    private var cacheIDS: [String] {
        if cache.count < 1 {
            return []
        }
        return cache.map { String($0.key) }
    }
    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("ProcyonSteamCache.plist")
    }
    private var cacheOwnedGamesIDsURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("ProcyonSteamOwnedGamesIDsCache.plist")
    }
    private var profileDataCacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("ProcyonSteamProfileDataCache.plist")
    }

    private func loadCache() {
        console.log("Loading caches...")
        self.loadGameCache()
        self.loadIDCache()
        self.loadBlacklistCache()
        self.loadProfileDataCache()
    }
    
    init() {
        self.loadCache()
        if(self.cache.isEmpty){
            console.warn("Cache is empty")
        }
        if(self.cacheOwnedGamesIDs.isEmpty){
            console.warn("ID Cache is empty")
        }
        if(self.cacheBlacklist.isEmpty){
            console.warn("Blacklist Cache is empty")
        }
    }
    private func loadGameCache() {
        do {
            let data = try Data(contentsOf: cacheURL)
            let decoded = try JSONDecoder().decode([String: SteamGame].self, from: data)
            self.cache = decoded
            if (self.cache.isEmpty == false){
                console.warn("Cache loaded")
            }
        } catch {
            console.error("Cache is empty, coulnd't read the file")
        }
    }
    private func saveGameCache() {
        do {
            let encoded = try JSONEncoder().encode(self.cache)
            try encoded.write(to: self.cacheURL, options: [.atomic])
            console.warn("Cache saved")
        } catch {
            console.error(String(reflecting: error))
        }
    }
    func deleteGameCache() {
        try? FileManager.default.removeItem(at: cacheURL)
        self.cache.removeAll()
        console.warn("Cache deleted")
    }
    private func loadIDCache() {
        do { // TO DO: Edge case - Track changes in the User ID and invalidate cache
            let data = try Data(contentsOf: cacheOwnedGamesIDsURL)
            let decoded = try JSONDecoder().decode([String].self, from: data)
            self.cacheOwnedGamesIDs = decoded
            if(self.cacheOwnedGamesIDs.isEmpty == false){
                console.warn("ID Cache loaded")
            }
        } catch {
            console.error("ID Cache is empty, coulnd't read the file")
        }
    }
    private func loadBlacklistCache() {
        do {
            let data = try Data(contentsOf: cacheBlacklistURL)
            let decoded = try JSONDecoder().decode([String].self, from: data)
            self.cacheBlacklist = decoded
            if(self.cacheBlacklist.isEmpty == false){
                console.warn("Blacklist Cache loaded")
            }
        } catch {
            console.error("Blacklist Cache is empty, coulnd't read the file")
        }
    }
    private func saveBlacklistCache() {
        do {
            let encoded = try JSONEncoder().encode(self.cacheBlacklist)
            try encoded.write(to: self.cacheBlacklistURL, options: [.atomic])
            console.warn("Blacklist cache saved")
        } catch {
            console.error(String(reflecting: error))
        }
    }
    func deleteBlacklistCache() {
        try? FileManager.default.removeItem(at: cacheBlacklistURL)
        self.cacheBlacklist.removeAll()
        console.warn("Blacklist Cache deleted")
    }
    func loadProfileDataCache() {
        do {
            let data = try Data(contentsOf: profileDataCacheURL)
            let decoded = try JSONDecoder().decode(UserInfo.self, from: data)
            self.cacheProfileData = decoded
            console.warn("Profile Data Cache loaded")
        } catch {
            console.error("Profile Data Cache is empty, couldn't read the file")
        }
    }
    func saveProfileDataCache() {
        do {
            let encoded = try JSONEncoder().encode(self.cacheProfileData)
            try encoded.write(to: self.profileDataCacheURL, options: [.atomic])
            console.warn("Profile Data Cache saved")
        } catch {
            console.error(String(reflecting: error))
        }
    }
    func deleteProfileDataCache() {
        try? FileManager.default.removeItem(at: profileDataCacheURL)
        self.cacheProfileData = nil
        // Reset to a minimal empty instance; if you prefer optional, make cacheProfileData optional instead.
        // Here we keep the type consistent by not mutating cacheProfileData.
        console.warn("Profile Data Cache deleted")
    }
    private func saveOwnedGamesIDsCache() {
        do {
            let encoded = try JSONEncoder().encode(self.cacheOwnedGamesIDs)
            try encoded.write(to: self.cacheOwnedGamesIDsURL, options: [.atomic])
            console.warn("IDs Cache saved")
        } catch {
            console.error(String(reflecting: error))
        }
    }

    func deleteOwnedGamesIDsCache() {
        try? FileManager.default.removeItem(at: cacheOwnedGamesIDsURL)
        self.cacheOwnedGamesIDs.removeAll()
        console.warn("IDs Cache deleted")
    }
    func fetchGameInfo(appID: String) async throws -> SteamGame? {
        if self.cacheBlacklist.contains(appID) {
            console.log("skipping \(appID) as it's blacklisted")
            return nil
        }
        if (self.cache[appID] != nil) {
            console.cache(appID, key: "gameCache")
            return self.cache[appID]
        }
        console.log("fetching \(appID) from the api")
        let urlString = "\(baseAPIURL)?appid=\(appID)"
        let headers: HTTPHeaders = ["x-api-key": apiKey]
        
        let data = try await AF.request(urlString, method: .get, headers: headers)
            .validate(statusCode: 200..<300)
            .serializingData()
            .value
        let root = try JSONDecoder().decode(SteamGameResponse.self, from: data)
        
        if(root.data.isEmpty) {
            console.warn("Game with id: \(appID) not found, blacklisting")
            self.cacheBlacklist.append(appID)
            return nil
        }
        cache[appID] = root.data[0]
        saveGameCache()
        return root.data[0]
        
    }
    func fetchGamesInfo(meta: [GamesMeta], setProgress: @escaping (Double) -> Void = { _ in }) async throws -> [Game] {
        var items: [Game] = []
        let total = meta.count
        // Reset progress at start
        self.progress = 0
        setProgress(self.progress)
        
        for (index, meta) in meta.enumerated() {
            let bDownloaded = Double(meta.BytesDownloaded ?? "0")!
            let bToDownload = Double(meta.BytesToDownload ?? "0")!
            let downloadProgress: Double = meta.isDownloaded() ? 100 : (bDownloaded / bToDownload) * 100            
            do {
                if let gameInfo = try await self.fetchGameInfo(appID: meta.appid) {
                    items.append(Game(from: gameInfo, id: meta.id, isNative: meta.isNative, downloadProgress: Double(downloadProgress), isInstalled: meta.installdir.isEmpty == false, appNames: []))
                }
            } catch {
                console.warn("Game with id: \(meta.appid) failed gracefully")
                console.error(String(reflecting: error))
            }
            // Update progress as percentage of total processed
            if total > 0 {
                let processed = index + 1
                let percent = (Double(processed) / Double(total)) * 100.0
                self.progress = percent
                setProgress(self.progress)
            }
        }
        // Ensure progress is 100% at completion when there were items to process
        if total > 0 {
            self.progress = 100
            setProgress(self.progress)
        }
        console.cacheRelease("The following game's data cache was used", key: "gameCache")
        self.saveBlacklistCache()
        return items.filter { item in
            !BLACKLIST.contains(String(describing: item.steamAppID))
        }
    }
    func fetchOwnedGamesIDs(userID: String) async throws -> [String] {
        if(self.cacheOwnedGamesIDs.count > 0) {
            console.log("Using cached user data")
            return self.cacheOwnedGamesIDs
        }
        let urlString = "\(baseAPIURL)/ownedGames/?userid=\(userID)"
        let headers: HTTPHeaders = ["x-api-key": apiKey]

        do {
            let data = try await AF.request(urlString, method: .get, headers: headers)
                .validate(statusCode: 200..<300)
                .serializingData()
                .value
            
            let root = try JSONDecoder().decode(SteamOwnedGamesResponseData.self, from: data)
            let ids = root.data.response.games.map { String($0.appID) }
            self.cacheOwnedGamesIDs = ids
            self.saveOwnedGamesIDsCache()
            return ids.filter { !self.cacheBlacklist.contains($0) }
        }
    }
    func fetchProfileDetails(userID: String) async throws -> UserInfo? {
        if(self.cacheProfileData != nil) {
            console.log("Using cached user data")
            return self.cacheProfileData!
        }
        let urlString = "\(baseAPIURL)/profile/?userid=\(userID)"
        let headers: HTTPHeaders = ["x-api-key": apiKey]

        do {
            let data = try await AF.request(urlString, method: .get, headers: headers)
                .validate(statusCode: 200..<300)
                .serializingData()
                .value
            
            let root = try JSONDecoder().decode(UserInfoResponse.self, from: data)
            let profileData = root.data
            self.cacheProfileData = profileData[0]
            self.saveProfileDataCache()
            return profileData[0]
        } catch {
            console.error(String(reflecting: error))
            return nil
        }
    }
    func fetchAutoConfig(steamID: String) async throws -> GameOptionsData? {
        if let cached = self.autoConfigCache[steamID] {
            console.log("Using cached user data")
            return cached
        }
        let urlString = "\(baseAPIURL)/settings/?steamID=\(steamID)"
        let headers: HTTPHeaders = ["x-api-key": apiKey]
        do {
            let data = try await AF.request(urlString, method: .get, headers: headers)
                .validate(statusCode: 200..<300)
                .serializingData()
                .value
            
            let root = try JSONDecoder().decode(GameOptionsDataResponse.self, from: data)
            let autoConfigData = root.data
            self.autoConfigCache[steamID]  = autoConfigData
            self.saveProfileDataCache()
            return autoConfigData
        } catch {
            console.error(String(reflecting: error))
            return nil
        }
    }
}

final class CustomGameAPI {
    var game: Game?
    private var cache: [String: Game] = [:]
    
    init() {
        //@TO DO: load cache
    }
    func fetch(hints: String) async throws -> Game? {
        let urlString = "\(baseAPIURL)/custom"
        let headers: HTTPHeaders = ["x-api-key": apiKey]
        let data = try await AF.request(urlString, method: .post, parameters: ["hints": hints], headers: headers) { $0.timeoutInterval = 120 }
            .validate(statusCode: 200..<300)
            .serializingData()
            .value
        let root = try JSONDecoder().decode(GameResponse.self, from: data)
        
//        cache[appID] = root.data[0]
//        saveGameCache()
        return root.data
    }
}
