//
//  Requirements.swift
//  Procyon
//
//  Created by Italo Mandara on 02/02/2026.
//

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

extension SteamGame {
    static let mock = SteamGame(
        type: "game",
        name: "Mock Game",
        steamAppID: 720,
        requiredAge: "18",
        isFree: false,
        controllerSupport: "full",
        dlc: [1111, 2222],
        detailedDescription: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua .\nUt enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. \nExcepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
        aboutTheGame: "About the mock game: fast-paced, fun, and engaging.",
        shortDescription: "A short description of the mock game.",
        supportedLanguages: "English, French, German",
        headerImage: "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/440/header.jpg",
        capsuleImage: "https://placehold.co/600x400/orange/white",
        capsuleImageV5: "https://placehold.co/600x400/orange/white",
        website: "https://example.com",
        pcRequirements: Requirements(minimum: "Windows 10, 8GB RAM", recommended: "Windows 11, 16GB RAM"),
        macRequirements: Requirements(minimum: "macOS 13, 8GB RAM", recommended: "macOS 14, 16GB RAM"),
        linuxRequirements: Requirements(minimum: "Ubuntu 22.04, 8GB RAM", recommended: "Ubuntu 24.04, 16GB RAM"),
        legalNotice: "All trademarks are property of their respective owners.",
        developers: ["Mock Dev Studio"],
        publishers: ["Mock Publisher"],
        priceOverview: PriceOverview(
            currency: "USD",
            initial: 1999,
            final: 999,
            discountPercent: 50,
            initialFormatted: "$19.99",
            finalFormatted: "$9.99"
        ),
        packages: [3333, 4444],
        packageGroups: [
            PackageGroup(
                name: "default",
                title: "Standard Edition",
                description: "Base game package",
                selectionText: "Select a purchase option",
                displayType: 0,
                subs: [
                    PackageSub(
                        packageID: 3333,
                        optionText: "Base Game",
                        isFreeLicense: false,
                        priceInCentsWithDiscount: 999
                    )
                ]
            )
        ],
        platforms: Platforms(windows: true, mac: true, linux: true),
        metacritic: Metacritic(score: 85, url: "https://metacritic.example.com/mockgame"),
        categories: [
            Category(id: 1, description: "Single-player"),
            Category(id: 2, description: "Online Co-op")
        ],
        genres: [
            Genre(id: "1", description: "Action"),
            Genre(id: "2", description: "Adventure")
        ],
        screenshots: [
            Screenshot(id: 1, pathThumbnail: "https://placehold.co/600x400/orange/white", pathFull: "https://placehold.co/600x400/orange/white"),
            Screenshot(id: 2, pathThumbnail: "https://placehold.co/600x400/orange/white", pathFull: "https://placehold.co/600x400/orange/white")
        ],
        movies: [
            Movie(id: 10, name: "Trailer", thumbnail: "https://example.com/trailer_thumb.jpg", dashH264: "https://video.akamai.steamstatic.com/store_trailers/440/129304/a9d97ffaf28cac468369400c12abe442a7b688b2/1749861261/dash_h264.mpd", hlsH264: "https://video.akamai.steamstatic.com/store_trailers/440/129304/a9d97ffaf28cac468369400c12abe442a7b688b2/1749861261/hls_264_master.m3u8", highlight: true)
        ],
        recommendations: Recommendations(total: 12345),
        achievements: Achievements(
            total: 100,
            highlighted: [Achievement(name: "First Steps", path: "https://placehold.co/600x400/orange/white")]
        ),
        releaseDate: ReleaseDate(comingSoon: false, date: "Jan 01, 2026"),
        supportInfo: SupportInfo(url: "https://support.example.com", email: "support@example.com"),
        background: "https://placehold.co/600x400/orange/white",
        backgroundRaw: "https://placehold.co/600x400",
        contentDescriptors: ContentDescriptors(ids: [1, 2, 3], notes: "Contains mild violence"),
        ratings: Ratings(
            esrb: RatingBody(rating: "T", requiredAge: "13", descriptors: "Violence"),
            pegi: RatingBody(rating: "16", requiredAge: "16", descriptors: "Violence"),
            usk: RatingBody(rating: "12", requiredAge: "12", descriptors: "Violence")
        )
    )
}
