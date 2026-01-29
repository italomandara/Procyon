//
//  API.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import Foundation

let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as! String
let proto = Bundle.main.object(forInfoDictionaryKey: "API_PROTOCOL") as! String
let host = Bundle.main.object(forInfoDictionaryKey: "API_HOST") as! String
let path = Bundle.main.object(forInfoDictionaryKey: "API_PATH") as! String

let baseAPIURL = "\(proto)://\(host)\(path)"

struct Requirements: Codable {
    let minimum: String?
    let recommended: String?
}

struct PriceOverview: Codable {
    let currency: String
    let initial: Int
    let final: Int
    let discountPercent: Int
    let initialFormatted: String
    let finalFormatted: String

    enum CodingKeys: String, CodingKey {
        case currency, initial, final
        case discountPercent = "discount_percent"
        case initialFormatted = "initial_formatted"
        case finalFormatted = "final_formatted"
    }
}

struct PackageGroup: Codable {
    let name: String
    let title: String
    let description: String
    let selectionText: String
    let displayType: Int
    let subs: [PackageSub]

    enum CodingKeys: String, CodingKey {
        case name, title, description
        case selectionText = "selection_text"
        case displayType = "display_type"
        case subs
    }
}

struct PackageSub: Codable {
    let packageID: Int
    let optionText: String
    let isFreeLicense: Bool
    let priceInCentsWithDiscount: Int

    enum CodingKeys: String, CodingKey {
        case packageID = "packageid"
        case optionText = "option_text"
        case isFreeLicense = "is_free_license"
        case priceInCentsWithDiscount = "price_in_cents_with_discount"
    }
}

struct Platforms: Codable {
    let windows: Bool
    let mac: Bool
    let linux: Bool
}

struct Screenshot: Codable {
    let id: Int
    let pathThumbnail: String
    let pathFull: String

    enum CodingKeys: String, CodingKey {
        case id
        case pathThumbnail = "path_thumbnail"
        case pathFull = "path_full"
    }
}

struct Movie: Codable {
    let id: Int
    let name: String
    let thumbnail: String
    let dashH264: String?
    let hlsH264: String?
    let highlight: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, thumbnail, highlight
        case dashH264 = "dash_h264"
        case hlsH264 = "hls_h264"
    }
}

struct Category: Codable {
    let id: Int
    let description: String
}

struct Genre: Codable {
    let id: String
    let description: String
}

struct Metacritic: Codable {
    let score: Int?
    let url: String?
}

struct Recommendations: Codable {
    let total: Int
}

struct ReleaseDate: Codable {
    let comingSoon: Bool
    let date: String

    enum CodingKeys: String, CodingKey {
        case comingSoon = "coming_soon"
        case date
    }
}

struct Achievements: Codable {
    let total: Int
    let highlighted: [Achievement]
}

struct Achievement: Codable {
    let name: String
    let path: String
}

struct SupportInfo: Codable {
    let url: String?
    let email: String?
}

struct ContentDescriptors: Codable {
    let ids: [Int]
    let notes: String?
}

struct Ratings: Codable {
    let esrb: RatingBody?
    let pegi: RatingBody?
    let usk: RatingBody?
}

struct RatingBody: Codable {
    let rating: String?
    let requiredAge: String?
    let descriptors: String?

    enum CodingKeys: String, CodingKey {
        case rating
        case requiredAge = "required_age"
        case descriptors
    }
}

struct SteamGame: Codable {
    let type: String
    let name: String
    let steamAppID: Int
    let requiredAge: String
    let isFree: Bool
    let controllerSupport: String?
    let dlc: [Int]?

    let detailedDescription: String
    let aboutTheGame: String
    let shortDescription: String
    let supportedLanguages: String?

    let headerImage: String
    let capsuleImage: String
    let capsuleImageV5: String?
    let website: String?

    let pcRequirements: Requirements?
    let macRequirements: Requirements?
    let linuxRequirements: Requirements?

    let legalNotice: String?
    let developers: [String]
    let publishers: [String]

    let priceOverview: PriceOverview?
    let packages: [Int]?
    let packageGroups: [PackageGroup]?

    let platforms: Platforms
    let metacritic: Metacritic?

    let categories: [Category]
    let genres: [Genre]?

    let screenshots: [Screenshot]?
    let movies: [Movie]?

    let recommendations: Recommendations?
    let achievements: Achievements?
    let releaseDate: ReleaseDate
    let supportInfo: SupportInfo?

    let background: String?
    let backgroundRaw: String?

    let contentDescriptors: ContentDescriptors?
    let ratings: Ratings?

    enum CodingKeys: String, CodingKey {
        case type, name
        case steamAppID = "steam_appid"
        case requiredAge = "required_age"
        case isFree = "is_free"
        case controllerSupport = "controller_support"
        case dlc
        case detailedDescription = "detailed_description"
        case aboutTheGame = "about_the_game"
        case shortDescription = "short_description"
        case supportedLanguages = "supported_languages"
        case headerImage = "header_image"
        case capsuleImage = "capsule_image"
        case capsuleImageV5 = "capsule_imagev5"
        case website
        case pcRequirements = "pc_requirements"
        case macRequirements = "mac_requirements"
        case linuxRequirements = "linux_requirements"
        case legalNotice = "legal_notice"
        case developers, publishers
        case priceOverview = "price_overview"
        case packages
        case packageGroups = "package_groups"
        case platforms, metacritic, categories, genres
        case screenshots, movies
        case recommendations, achievements
        case releaseDate = "release_date"
        case supportInfo = "support_info"
        case background
        case backgroundRaw = "background_raw"
        case contentDescriptors = "content_descriptors"
        case ratings
    }
}

extension SteamGame: Identifiable {
    var id: Int { steamAppID }
}

struct SteamGameResponse: Codable {
    let data: [SteamGame]
}

enum APIError: Error {
    case badURL
    case invalidResponse
}

final class SteamAPI {
    private var cache: [String: [SteamGame]] = [:]
    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("SteamCache.plist")
    }
    var hasCache: Bool { !cache.isEmpty }
    init() {
        loadCache()
    }
    private func loadCache() {
        do {
            let data = try Data(contentsOf: cacheURL)
            let decoded = try JSONDecoder().decode([String: [SteamGame]].self, from: data)
            self.cache = decoded
            print("Cache loaded")
        } catch {
            print("Cache is empty")
        }
    }
    private func saveCache() {
        do {
            let encoded = try JSONEncoder().encode(self.cache)
            try encoded.write(to: self.cacheURL, options: [.atomic])
            print("Cache saved")
        } catch {
            print(error)
        }
    }
    func deleteCache() {
        try? FileManager.default.removeItem(at: cacheURL)
        self.cache.removeAll()
        print("Cache deleted")
    }
    func fetchGameInfo(appID: String) async throws -> [SteamGame]? {
        if let cached = cache[appID] {
            print("Returning from cache for id \(appID)")
            return cached
        }
        print("baseAPIURL: \(baseAPIURL)")
        print("apiKey: \(apiKey)")
        let urlString = "\(baseAPIURL)?appid=\(appID)"
        
        guard let url = URL(string: urlString) else { throw APIError.badURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("\(apiKey)", forHTTPHeaderField: "x-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)
        print("accessing API at \(urlString)")
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()

        do {
            let root = try decoder.decode(SteamGameResponse.self, from: data)
            print("Decoded \(root.data.count) items for game \(appID)")
            cache[appID] = root.data
            saveCache()
            return root.data
        } catch {
            print("Decoding failed: \(error) for id \(appID)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type) — \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("Key not found: \(key) — \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type \(type) — \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error: \(error)")
                }
            }
        }
        return []
    }
    func fetchGamesInfo(appIDs: [String]) async throws -> [SteamGame] {
        var items: [SteamGame] = []
        for appID in appIDs {
            if let gameInfo = try await self.fetchGameInfo(appID: appID) {
                items.append(contentsOf: gameInfo)
            }
        }
        return items
    }
}
