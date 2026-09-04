//
//  GameThumbnail.swift
//  Procyon
//
//  Created by Italo Mandara on 30/01/2026.
//

import SwiftUI
import Kingfisher

struct GameThumbnail: View {
    var item: Game
    var isResizable: Bool = false
    @EnvironmentObject var appGlobals: AppGlobals
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    @State private var tObserver: TerminationObserver?
    var isPlaying: Bool {
        libraryPageGlobals.playingID == item.id
    }
    var isDownloading: Bool {
        item.downloadProgress < 100
    }
    var updatedItem: Game {
        var newItem = item
        if let meta = libraryPageGlobals.gamesMeta.first(where: { $0.id == item.id }){
            
            newItem.appNames = getAppNames(isNative: meta.isNative, gameURL: meta.gameURL)
            return newItem
        }
        return newItem
    }
    
    var body: some View {
        Button(action: {
            openDetailPage()
        }) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing){
                    KFImage(URL(string: item.headerImage))
                        .placeholder {
                            if !item.headerImage.isEmpty { ProgressView() }
                        }
                        .onFailureView { Color.clear }
                        .resizable()
                        .aspectRatio(2.15, contentMode: .fit)
                        .frame(maxWidth:.infinity, maxHeight: .infinity, alignment: .top)
                        
                    HStack(alignment: .top) {
                        if (item.isNative == true) {
                            OIcon("apple.logo").padding(.vertical, 8)            // icon size
                        }
                        if (item.isCustom == true) {
                            Button {
                                libraryPageGlobals.deleteCustomAddedGame(game: item)
                            } label: {
                                OIcon("trash").padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                VStack (alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)
                    HStack (spacing: 6){
                        AccentTag(item.type)
                        if (item.genres != nil && item.genres!.count > 0){
                            AccentTag(item.genres!.first!.description)
                        }
                        if (item.isInstalled) {
                            if (item.isNative == true) {
                                AccentTag("Mac")
                            } else {
                                AccentTag("Pc")
                            }
                        }
                        Spacer()
                        
                        if(!isDownloading && item.isInstalled) {
                            Button {
                                if (isPlaying) {
                                    if(item.isNative) {
                                        console.log("stop action not implemented for macOS")
                                    } else {
                                        Task {
                                            try! await closeWineActivities()
                                            libraryPageGlobals.playingID = nil
                                        }
                                    }
                                } else {
                                    PlayGame()
                                }
                            } label: {
                                Label(isPlaying ? "Stop" :"Play", systemImage: isPlaying ? "stop.fill" : "play.fill").foregroundStyle(.black)
                            }
                            .background(.procyonSecondary)
                            .cornerRadius(20)
                        } else if(item.isInstalled) {
                            ProgressView(value: item.downloadProgress, total: 100,
                                         label: { Text("Downloading...").font(.footnote)
                            }).frame(height: 30)
                        } else {
                            Button {
                                // TO DO: Install script
                            }
                            label: {
                                Label("Install", systemImage: "square.and.arrow.down").foregroundStyle(.black)
                            }
                            .cornerRadius(20)
                        }
                    }
                    .padding(.bottom, 8)
                }.foregroundStyle(.white)
                    .padding(.horizontal)
                }
            .background(.procyonAccent.mix(with: .black, by: 0.6).opacity(0.8))
            .cornerRadius(30)
        }
        .buttonStyle(.plain)
        .frame(height: isResizable ? nil : 214)
    }
    
    @MainActor
    func PlayGame () {
        libraryPageGlobals.selectedGame = updatedItem
        libraryPageGlobals.setLoader(state: true)
        if (isPlaying) {
            return
        }
        Task {
            do {
                let id = item.steamAppID != 0 ? String(describing: item.steamAppID) : String(describing: item.id)
                let gameOptKey = namespacedKey("GameOptions", id)
                let gameOptions: GameOptions = GameOptions()
                if let gameOptionsData: GameOptionsData = readUsrDefData(key: gameOptKey) {
                    gameOptions.set(data: gameOptionsData)
                    console.log("options retrieved")
                } else {
                    console.warn("failed to retrieve game options")
                }
                Task(priority: .background) {
                    tObserver = try await getGameTracker(appNames: updatedItem.appNames, cxAppPath: appGlobals.cxAppPath!, bottleName: appGlobals.selectedBottle, onLoad: { appName in 
                        libraryPageGlobals.playingID = item.id
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            libraryPageGlobals.setLoader(state: false)
                            Task {
                                activateApp(appName)
                            }
                        }
                    }, onTerminate: {
                        libraryPageGlobals.setLoader(state: false) // if doesn't get loaded i need to close the loader
                        libraryPageGlobals.playingID = nil
                        tObserver = nil
                    }, isNative: item.isNative, steamID: item.isCustom == true ? nil : item.steamAppID, steamPath: appGlobals.windowsSteamFolder?.path(percentEncoded: false) ?? "")
                }
                if(item.isNative) {
                    try await launchNativeGame(id: String(item.steamAppID), cxAppPath: appGlobals.cxAppPath ?? "", selectedBottle: appGlobals.selectedBottle, options: gameOptions, appExeURL: item.appExeURL)
                } else {
                    if(item.isCustom == true && item.appExeURL == nil) {
                        console.error("custom game doesn't have an executable associated")
                        libraryPageGlobals.setLoader(state: false)
                        return
                    }
                    let steamExePath = appGlobals.windowsSteamFolder?.appendingPathComponent("Steam.exe").path(percentEncoded: false) ?? "C:\\Program Files (x86)\\Steam\\Steam.exe"
                    try await launchWindowsGame(id: String(item.steamAppID), cxAppPath: appGlobals.cxAppPath ?? "", selectedBottle: appGlobals.selectedBottle, steamExePath: steamExePath, options: gameOptions, appExeURL: item.appExeURL)
                }
            } catch {
                console.error(String(reflecting: error))
                libraryPageGlobals.setLoader(state: false)
            }
        }
    }
    
    func openDetailPage() {
        libraryPageGlobals.selectedGame = updatedItem
        libraryPageGlobals.showDetailView =  true
    }
}

#Preview {
    GameThumbnail(item: .mock)
}
