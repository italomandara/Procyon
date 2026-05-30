//
//  GameHeader.swift
//  Procyon
//
//  Created by Italo Mandara on 05/02/2026.
//

import SwiftUI

struct GameHeader: View {
    @Binding var game: Game?
    @Binding var showDetailView: Bool
    @EnvironmentObject var appGlobals: AppGlobals
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    @EnvironmentObject var gameOptions: GameOptions
    @State private var showGameOptions: Bool = false
    var isPlaying: Bool {
        libraryPageGlobals.playingID == game!.id
    }
    @State private var tObserver: TerminationObserver?
    
    var developers: String {
        "Developer: \(game!.developers.joined(separator: ", "))"
    }
    
    var publishers: String { // @To do: DRY
        "Publisher: \(game!.publishers.joined(separator: ", "))"
    }
    
    var body: some View {
        HStack (alignment: .bottom) {
            VStack(alignment: .leading){
                Text(game!.name).font(.largeTitle.bold())
                Text(developers).font(.footnote)
                Text(publishers).font(.footnote)
            }
            HStack(alignment: .center) {
                if(game!.downloadProgress == 100 && game!.isInstalled) {
                    PlayButtonExtras(playAction: playGame,
                    stopAction: {
                        if(game!.isNative) {
                            console.log("stop action not implemented for macOS")
                        } else {
                            Task {
                                try! await closeWineActivities()
                                libraryPageGlobals.playingID = nil
                            }
                        }
                    }, optionsAction: {
                        showGameOptions = true
                    }, folderAction: {
                        if let meta = getMeta(libraryPageGlobals.gamesMeta, byID: String(game!.id)) {
                            showFolder(url: meta.gameURL!)
                        } else if game!.appExeURL != nil {
                            showFolder(url: game!.appExeURL!.deletingLastPathComponent())
                        }
                    }, isPlaying: isPlaying)
                }
            Spacer()
            
                HStack{
                    if(game!.isNative == true) {
                        Image(systemName: "apple.logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .foregroundStyle(.white)
                        
                    }
                    if(game!.controllerSupport == "full") {
                        Image(systemName: "gamecontroller.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .foregroundStyle(.white)
                        
                    }
                }
                HStack(alignment: .center){
                    Text("Available for:")
                    if (game!.platforms.mac) {
                        Image("os-apple")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                    }
                    if (game!.platforms.linux) {
                        Image("os-linux")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                    }
                    if (game!.platforms.windows) {
                        Image("os-win")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 30)
                .background(.clear)
                .overlay(
                    Capsule()
                        .stroke(.white, lineWidth: 2)
                )
                .clipShape(.capsule)
            }
        }
        .foregroundStyle(.white)
        .sheet(isPresented: $showGameOptions) {
            Modal("Options for \(game!.name)", showModal: $showGameOptions) {
                GameOptionsView(game: $game)
            }
        }
    }
    
    @MainActor
    func playGame() {
        libraryPageGlobals.setLoader(state: true)
        Task {
            do {
                Task(priority: .background) {
                    tObserver = try await getGameTracker(appNames: game!.appNames, cxAppPath: appGlobals.cxAppPath, bottleName: appGlobals.selectedBottle, onLoad: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            libraryPageGlobals.setLoader(state: false)
                        }
                        libraryPageGlobals.playingID = game!.id
                    }, onTerminate: {
                        libraryPageGlobals.setLoader(state: false) // if doesn't get loaded i need to close the loader
                        libraryPageGlobals.playingID = nil
                        tObserver = nil
                    }, isNative: game!.isNative)
                }
                if(game!.isNative) {
                    try await launchNativeGame(id: String(game!.steamAppID), cxAppPath: appGlobals.cxAppPath, selectedBottle: appGlobals.selectedBottle, options: gameOptions, appExeURL: game!.appExeURL)
                } else {
                    if(game!.isCustom == true && game!.appExeURL == nil) {
                        console.error("custom game doesn't have an executable associated")
                        libraryPageGlobals.setLoader(state: false)
                        return
                    }
                    try await launchWindowsGame(id: String(game!.steamAppID), cxAppPath: appGlobals.cxAppPath, selectedBottle: appGlobals.selectedBottle, options: gameOptions, appExeURL: game!.appExeURL, steamWinePath: appGlobals.steamWinePath)
                }
            } catch {
                libraryPageGlobals.setLoader(state: false)
                console.error("Error launching game: \(String(reflecting: error))")
            }
            showDetailView = false
        }
    }
}
