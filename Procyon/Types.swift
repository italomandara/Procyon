//
//  Types.swift
//  Procyon
//
//  Created by Italo Mandara on 19/02/2026.
//

import Foundation
import Combine

typealias DropdownOptions = [(id: String, label: String)]

let cxGraphicsBackend: DropdownOptions = [
    (id: "dxmt", label: "DXMT"),
    (id: "d3dmetal", label: "D3Dmetal"),
    (id: "wined3d", label: "Wine"),
    (id: "dxvk", label: "DXVK"),
    (id: "auto", label: "Auto")
]

let cxVulkanBackend: DropdownOptions = [
    (id: "", label: "Standard"),
    (id: "latest", label: "Latest"),
    (id: "experimental", label: "Experimental"),
    (id: "dbh", label: "Detroit Become Human"),
//    (id: "kosmickrisp", label: "KosmicKrisp")
]

enum OnOff: String {
    case off = "0"
    case on = "1"
}

typealias CXDrives = [String: URL]

struct GameOptionsData: Codable { // this is used for reading saved properties
    var cxGraphicsBackend: String
    var wineMSync: Bool
    var mtlHudEnabled: Bool
    var d3dMtl4Enabled: Bool
    var x87PatchEnabled: Bool
    var dx9PatchEnabled: Bool
    var gameArguments: String
    var dxmtPreferredMaxFrameRate: Double
    var dxmtMetalFXSpatial: Bool
    var dxmtMetalSpatialUpscaleFactor: Double
    var advertiseAVX: Bool
    var envVariables: String
    var enableSDL: Bool
    var disableHidraw: Bool
    var ue4Hack: Bool
    var mvkArgBuff: Bool
    var vulkanLib: String
    var dxvk: String?
    var wineEsync: String?
    var d3dMEnableMetalFX: String?
    var d3dSupportDXR: String?
    var d3dMaxFPS: Double
    
    init(data: GameOptions) {
        self.cxGraphicsBackend = data.cxGraphicsBackend
        self.wineMSync = data.wineMSync
        self.mtlHudEnabled = data.mtlHudEnabled
        self.x87PatchEnabled = data.x87PatchEnabled
        self.dx9PatchEnabled = data.dx9PatchEnabled
        self.gameArguments = data.gameArguments
        self.dxmtPreferredMaxFrameRate = data.dxmtPreferredMaxFrameRate
        self.dxmtMetalFXSpatial = data.dxmtMetalFXSpatial
        self.dxmtMetalSpatialUpscaleFactor = data.dxmtMetalSpatialUpscaleFactor
        self.advertiseAVX = data.advertiseAVX
        self.envVariables = data.envVariables
        self.enableSDL = data.enableSDL
        self.disableHidraw = data.disableHidraw
        self.ue4Hack = data.ue4Hack
        self.mvkArgBuff = data.mvkArgBuff
        self.vulkanLib = data.vulkanLib
        self.dxvk = data.dxvk
        self.wineEsync = data.wineEsync
        self.d3dMEnableMetalFX = data.d3dMEnableMetalFX
        self.d3dSupportDXR = data.d3dSupportDXR
        self.d3dMtl4Enabled = data.d3dMtl4Enabled
        self.d3dMaxFPS = data.d3dMaxFPS
    }
}

class GameOptions: ObservableObject { // this is used as form state
    @Published var cxGraphicsBackend: String
    @Published var wineMSync: Bool
    @Published var mtlHudEnabled: Bool
    @Published var x87PatchEnabled: Bool
    @Published var dx9PatchEnabled: Bool
    @Published var gameArguments: String
    @Published var dxmtPreferredMaxFrameRate: Double
    @Published var dxmtMetalFXSpatial: Bool
    @Published var dxmtMetalSpatialUpscaleFactor: Double
    @Published var advertiseAVX: Bool
    @Published var envVariables: String
    @Published var enableSDL: Bool
    @Published var disableHidraw: Bool
    @Published var ue4Hack: Bool
    @Published var mvkArgBuff: Bool
    @Published var vulkanLib: String
    @Published var dxvk: String?
    @Published var wineEsync: String?
    @Published var d3dMEnableMetalFX: String?
    @Published var d3dSupportDXR: String?
    @Published var d3dMtl4Enabled: Bool
    @Published var d3dMaxFPS: Double
    
    init(cxGraphicsBackend: String = "d3dmetal", wineMSync: Bool = true, mtlHudEnabled: Bool = false, d3dMtl4Enabled: Bool = false, x87PatchEnabled: Bool = false, dx9PatchEnabled: Bool = false, gameArguments: String = "", dxmtPreferredMaxFrameRate: Double = 0, dxmtMetalFXSpatial: Bool = false, dxmtMetalSpatialUpscaleFactor: Double = 1.0, advertiseAVX: Bool = true, envVariables: String = "", sdlEnabled: Bool = true, hidrawDisabled: Bool = false, ue4Hack: Bool = true, mvkArgBuff: Bool = true, vulkanLib: String = "latest", dxvk: String? = nil, wineEsync: String? = nil, d3dMEnableMetalFX: String? = nil, d3dMaxFPS: Double = 0, d3dSupportDXR: String? = nil) {
        self.cxGraphicsBackend = cxGraphicsBackend
        self.wineMSync = wineMSync
        self.mtlHudEnabled = mtlHudEnabled
        self.x87PatchEnabled = x87PatchEnabled
        self.dx9PatchEnabled = dx9PatchEnabled
        self.gameArguments = gameArguments
        self.dxmtMetalFXSpatial = dxmtMetalFXSpatial
        self.dxmtMetalSpatialUpscaleFactor = dxmtMetalSpatialUpscaleFactor
        self.dxmtPreferredMaxFrameRate = dxmtPreferredMaxFrameRate
        self.advertiseAVX = advertiseAVX
        self.envVariables = envVariables
        self.enableSDL = sdlEnabled
        self.disableHidraw = hidrawDisabled
        self.ue4Hack = ue4Hack
        self.mvkArgBuff = mvkArgBuff
        self.vulkanLib = vulkanLib
        self.dxvk = dxvk
        self.wineEsync = wineEsync
        self.d3dMEnableMetalFX = d3dMEnableMetalFX
        self.d3dSupportDXR = d3dSupportDXR
        self.d3dMtl4Enabled = d3dMtl4Enabled
        self.d3dMaxFPS = d3dMaxFPS
    }
    
    func set(data: GameOptionsData) {
        self.cxGraphicsBackend = data.cxGraphicsBackend
        self.wineMSync = data.wineMSync
        self.mtlHudEnabled = data.mtlHudEnabled
        self.x87PatchEnabled = data.x87PatchEnabled
        self.dx9PatchEnabled = data.dx9PatchEnabled
        self.gameArguments = data.gameArguments
        self.dxmtMetalFXSpatial = data.dxmtMetalFXSpatial
        self.dxmtMetalSpatialUpscaleFactor = data.dxmtMetalSpatialUpscaleFactor
        self.dxmtPreferredMaxFrameRate = data.dxmtPreferredMaxFrameRate
        self.advertiseAVX = data.advertiseAVX
        self.envVariables = data.envVariables
        self.enableSDL = data.enableSDL
        self.disableHidraw = data.disableHidraw
        self.ue4Hack = data.ue4Hack
        self.mvkArgBuff = data.mvkArgBuff
        self.vulkanLib = data.vulkanLib
        self.dxvk = data.dxvk
        self.wineEsync = data.wineEsync
        self.d3dMEnableMetalFX = data.d3dMEnableMetalFX
        self.d3dSupportDXR = data.d3dSupportDXR
        self.d3dMtl4Enabled = data.d3dMtl4Enabled
        self.d3dMaxFPS = data.d3dMaxFPS
    }
}

class GamesMeta: SteamACFMeta {
    var gameURL: URL?
    var libraryFolder: URL
    var isNative: Bool
    var appNames: [String]
    var id: String { libraryFolder.relativeString + appid }
    func isDownloaded() -> Bool {
        return (self.BytesToDownload == "0" || self.BytesToDownload == self.BytesDownloaded)
    }
    
    init(appid: String, installdir: String, gameURL: URL? = nil, isNative: Bool = false, libraryFolder: URL = URL(string: "/")!, bytesDownloaded: String, BytesTodownload: String, appNames: [String] = []) {
        self.gameURL = gameURL
        self.isNative = isNative
        self.libraryFolder = libraryFolder
        self.appNames = appNames
        super.init()
        self.appid = appid
        self.installdir = installdir
        self.BytesDownloaded = bytesDownloaded
        self.BytesToDownload = BytesTodownload
        self.appNames = appNames
    }
}

struct Game: Identifiable, Codable {
    var id: String
    var isNative: Bool
    var downloadProgress: Double
    var isInstalled: Bool
    var appNames: [String] = []
    var appExeURL: URL?
    var isCustom: Bool?
    
    // taken from SteamGame
    let type: String
    var name: String
    let steamAppID: Int
    let requiredAge: String
    let isFree: Bool
    let controllerSupport: String?
    let dlc: [Int]?
    
    var detailedDescription: String
    var aboutTheGame: String
    var shortDescription: String
    let supportedLanguages: String?
    
    var headerImage: String
    let capsuleImage: String
    let capsuleImageV5: String?
    let website: String?
    
    let pcRequirements: Requirements?
    let macRequirements: Requirements?
    let linuxRequirements: Requirements?
    
    let legalNotice: String?
    var developers: [String]
    var publishers: [String]
    
    let priceOverview: PriceOverview?
    let packages: [Int]?
    let packageGroups: [PackageGroup]?
    
    var platforms: Platforms
    let metacritic: Metacritic?
    
    var categories: [Category]
    var genres: [Genre]?
    
    let screenshots: [Screenshot]?
    let movies: [Movie]?
    
    let recommendations: Recommendations?
    let achievements: Achievements?
    let releaseDate: ReleaseDate
    let supportInfo: SupportInfo?
    
    let background: String?
    let backgroundRaw: String?
    
    let contentDescriptors: ContentDescriptors?
    let ratings: [String: RatingBody]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isNative = "is_native"
        case downloadProgress = "download_progress"
        case isInstalled = "is_installed"
        case appNames = "app_names"
        case appExeURL = "app_exe_url"
        case isCustom = "is_custom"
        
        case type
        case name
        case steamAppID = "steam_app_id"
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
        case capsuleImageV5 = "capsule_image_v5"
        case website
        
        case pcRequirements = "pc_requirements"
        case macRequirements = "mac_requirements"
        case linuxRequirements = "linux_requirements"
        
        case legalNotice = "legal_notice"
        case developers
        case publishers
        
        case priceOverview = "price_overview"
        case packages
        case packageGroups = "package_groups"
        
        case platforms
        case metacritic
        
        case categories
        case genres
        
        case screenshots
        case movies
        
        case recommendations
        case achievements
        case releaseDate = "release_date"
        case supportInfo = "support_info"
        
        case background
        case backgroundRaw = "background_raw"
        
        case contentDescriptors = "content_descriptors"
        case ratings
    }
    
    init(from: SteamGame, id: String, isNative: Bool, downloadProgress: Double, isInstalled: Bool, appNames: [String], isCustom: Bool? = false) {
        self.id = id
        self.isNative = isNative
        self.downloadProgress = downloadProgress
        self.isInstalled = isInstalled
        self.appNames = appNames
        
        // SteamGame property
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
        self.developers = from.developers ?? []
        self.publishers = from.publishers ?? []
        
        self.priceOverview = from.priceOverview
        self.packages = from.packages
        self.packageGroups = from.packageGroups
        
        self.platforms = from.platforms
        self.metacritic = from.metacritic
        
        self.categories = from.categories ?? []
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
                displayType: "0",
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
            Movie(id: 10, name: "Trailer", thumbnail: "https://example.com/trailer_thumb.jpg", dashH264: "https://video.akamai.steamstatic.com/store_trailers/440/129304/a9d97ffaf28cac468369400c12abe442a7b688b2/1749861261/dash_h264.mpd", hlsH264: "https://video.akamai.steamstatic.com/store_trailers/440/129304/a9d97ffaf28cac468369400c12abe4427b688b2/1749861261/hls_264_master.m3u8", highlight: true)
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
        ratings: [
            "esrb": RatingBody(rating: "T", requiredAge: "13", descriptors: "Violence"),
            "pegi": RatingBody(rating: "16", requiredAge: "16", descriptors: "Violence"),
            "usk": RatingBody(rating: "12", requiredAge: "12", descriptors: "Violence")
        ]
    )
    static let mock = Game(from: Game.steamMock, id: "example", isNative: true, downloadProgress: 100, isInstalled: true, appNames: ["test.exe"], isCustom: true)
    static let steamEmptyGame = SteamGame(
        type: "game",
        name: "Game Name here",
        steamAppID: 0,
        requiredAge: "18",
        isFree: false,
        controllerSupport: "full",
        dlc: [],
        detailedDescription: "Game description here",
        aboutTheGame: "Game description here",
        shortDescription: "Short game description here",
        supportedLanguages: "English",
        headerImage: "",
        capsuleImage: "",
        capsuleImageV5: nil,
        website: "",
        pcRequirements: Requirements(minimum: "Windows 10, 8GB RAM", recommended: "Windows 11, 16GB RAM"),
        macRequirements: nil,
        linuxRequirements: nil,
        legalNotice: "All trademarks are property of their respective owners.",
        developers: [""],
        publishers: [""],
        priceOverview: PriceOverview(
            currency: "USD",
            initial: 0,
            final: 0,
            discountPercent: 0,
            initialFormatted: "$0",
            finalFormatted: "$0"
        ),
        packages: [],
        packageGroups: [],
        platforms: Platforms(windows: true, mac: false, linux: false),
        metacritic: nil,
        categories: [],
        genres: [],
        screenshots: nil,
        movies: nil,
        recommendations: nil,
        achievements: nil,
        releaseDate: ReleaseDate(comingSoon: false, date: "Jan 01, 2026"),
        supportInfo: nil,
        background: nil,
        backgroundRaw: nil,
        contentDescriptors: nil,
        ratings: nil
    )
    static let emptyGame = Game(from: Game.steamEmptyGame, id: "example", isNative: true, downloadProgress: 100, isInstalled: true, appNames: ["test.exe"])
}

struct GameResponse: Codable, Sendable {
    let data: Game
}

enum SortingOptions {
    case name
    case releaseDate
    case publisher
    case developer
    case installed
}

class LibraryPageGlobals: ObservableObject {
    @Published var gamesMeta: [GamesMeta] = []
    @Published var folders: [String] = []
    @Published var showOptions: Bool = false
    @Published var filter: String = ""
    @Published var showDetailView = false
    @Published var selectedGame: Game? = nil
    @Published var isLaunchingGame: Bool = false
    @Published var customAddedGames: [Game] = []
    @Published var games: [Game] = []
    @Published var sortBy: SortingOptions = SortingOptions.name
    @Published var playingID: String?
    
    init() {
        self.loadCustomAddedGames()
    }
    
    var allGamesCount: Int {
        return self.games.count + self.customAddedGames.count
    }
    
    var allGames: [Game] {
        self.games + self.customAddedGames
    }
    
    var filteredGames: [Game] {
        var games: [Game] = self.allGames
        if self.filter.isEmpty || self.filter.count < 3 {
            games = self.allGames
        } else {
            games = allGames.filter { item in
                self.filter.isEmpty || item.name.lowercased().contains(self.filter.lowercased())
            }
        }
        return games.sorted { lhs, rhs in
            switch self.sortBy {
            case SortingOptions.name:
                return lhs.name.lowercased() < rhs.name.lowercased()
            case .releaseDate:
                return lhs.releaseDate.date < rhs.releaseDate.date
            case .publisher:
                if(lhs.publishers.isEmpty) && (!rhs.publishers.isEmpty) { return false }
                if(!lhs.publishers.isEmpty) && (rhs.publishers.isEmpty) { return true }
                return lhs.publishers[0].lowercased() < rhs.publishers[0].lowercased()
            case .developer:
                if(lhs.developers.isEmpty) && (!rhs.developers.isEmpty) { return false }
                if(!lhs.developers.isEmpty) && (rhs.developers.isEmpty) { return true }
                return lhs.developers[0].lowercased() < rhs.developers[0].lowercased()
            case .installed:
                return lhs.isInstalled && !rhs.isInstalled
            }
        }
    }
    
    func loadCustomAddedGames() {
        let groupDefaults = UserDefaults(suiteName: suiteName)!
        if let savedGamesData = groupDefaults.data(forKey: "customAddedGames") {
            let decoder = JSONDecoder()
            guard let savedGames = try? decoder.decode([Game].self, from: savedGamesData) else { return }
            self.customAddedGames = savedGames
        }
    }
    
    func getCustomAddedGame(id: String) -> Game? {
        return self.customAddedGames.first(where: { $0.id == id })
    }
    
    func saveCustomAddedGames() {
        let groupDefaults = UserDefaults(suiteName: suiteName)!
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self.customAddedGames) else { return }
        groupDefaults.set(data, forKey: "customAddedGames")
    }
    
    func updateCustomAddedGames(gameData: Game) {
        if let index = self.customAddedGames.firstIndex(where: { $0.id == gameData.id }) {
            console.log("game \(self.customAddedGames[index].name) is being updated")
            console.log(String(describing: gameData))
            self.customAddedGames[index] = gameData
        }
        let groupDefaults = UserDefaults(suiteName: suiteName)!
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self.customAddedGames) else { return }
        groupDefaults.set(data, forKey: "customAddedGames")
    }
    
    func deleteCustomAddedGame(game: Game) {
        self.customAddedGames.removeAll { $0.id == game.id }
        saveCustomAddedGames()
    }
    
    func setLoader(state: Bool) {
        isLaunchingGame = state
    }
    
    func setPlayingID( _ id: String?) {
        playingID = id
    }
}

final class AppGlobals: ObservableObject {
    @Published var selectedBottle: String = ""
    @Published var userID: String? = nil
    @Published var cxAppPath: String?
    @Published var windowsSteamFolder: URL?
    
    init(selectedBottle: String? = "", cxAppPath: String? = nil) {
        self.selectedBottle = readUsrDefOptionString(key: "selectedBottle") ?? ""
        self.cxAppPath = readUsrDefOptionString(key: "cxAppPath")
    }
}

