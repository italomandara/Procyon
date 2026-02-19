//
//  Types.swift
//  Procyon
//
//  Created by Italo Mandara on 19/02/2026.
//

import Foundation

class GamesMeta: SteamACFMeta {
    var gameURL: URL?
    var libraryFolder: URL?
    var isNative: Bool
    
    init(appid: String, installdir: String, gameURL: URL? = nil, isNative: Bool = false, libraryFolder: URL? = nil) {
        self.gameURL = gameURL
        self.isNative = isNative
        self.libraryFolder = libraryFolder
        super.init()
        self.appid = appid
        self.installdir = installdir
    }
}
