//
//  Types.swift
//  Procyon
//
//  Created by Italo Mandara on 19/02/2026.
//

import Foundation

class GamesMeta: SteamACFMeta {
    var gameURL: URL?
    var libraryFolder: URL
    var isNative: Bool
    var id: String { libraryFolder.relativeString + appid }
    
    init(appid: String, installdir: String, gameURL: URL? = nil, isNative: Bool = false, libraryFolder: URL = URL(string: "/")!) {
        self.gameURL = gameURL
        self.isNative = isNative
        self.libraryFolder = libraryFolder
        super.init()
        self.appid = appid
        self.installdir = installdir
    }
}

struct Game: Identifiable {
    var id: String
    
    // taken from SteamGame
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
    
    init(from: SteamGame, id: String) {
        self.id = id
        self.type = from.type
        self.name = from.name
        self.steamAppID = from.steamAppID
        self.requiredAge = from.requiredAge
        self.isFree = from.isFree
        self.controllerSupport = from.controllerSupport
        self.dlc = from.dlc
        
        self.detailedDescription = from.detailedDescription
        self.aboutTheGame = from.aboutTheGame
        self.shortDescription = from.shortDescription
        self.supportedLanguages = from.supportedLanguages
        
        self.headerImage = from.headerImage
        self.capsuleImage = from.capsuleImage
        self.capsuleImageV5 = from.capsuleImageV5
        self.website = from.website
        
        self.pcRequirements = from.pcRequirements
        self.macRequirements = from.macRequirements
        self.linuxRequirements = from.linuxRequirements
        
        self.legalNotice = from.legalNotice
        self.developers = from.developers
        self.publishers = from.publishers
        
        self.priceOverview = from.priceOverview
        self.packages = from.packages
        self.packageGroups = from.packageGroups
        
        self.platforms = from.platforms
        self.metacritic = from.metacritic
        
        self.categories = from.categories
        self.genres = from.genres
        
        self.screenshots = from.screenshots
        self.movies = from.movies
        
        self.recommendations = from.recommendations
        self.achievements = from.achievements
        self.releaseDate = from.releaseDate
        self.supportInfo = from.supportInfo
        
        self.background = from.background
        self.backgroundRaw = from.backgroundRaw
        
        self.contentDescriptors = from.contentDescriptors
        self.ratings = from.ratings
    }
}

extension Game {
    static let steamMock = SteamGame(
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
    static let mock = Game(from: Game.steamMock, id: "example")
}
