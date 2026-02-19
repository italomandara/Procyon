//
//  Types.swift
//  Procyon
//
//  Created by Italo Mandara on 19/02/2026.
//

import Foundation

class GamesMeta: SteamACFMeta {
    var libraryURL: URL?
    
    init(appid: String, installdir: String, libraryURL: URL? = nil) {
        self.libraryURL = libraryURL
        super.init()
        self.appid = appid
        self.installdir = installdir
    }
}
