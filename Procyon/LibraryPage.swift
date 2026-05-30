//
//  LibraryPage.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import SwiftUI
import Combine
import Kingfisher

struct LibraryPage: View {
    @StateObject var libraryPageGlobals = LibraryPageGlobals()
    @EnvironmentObject var appGlobals: AppGlobals
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var progress: Double = 0
    @State private var selectedGame: SteamGame? = nil
    @State private var mntObserver: MountObserver?
    @State private var showAddCustomGameView: Bool = false
    
    var body: some View {
        ZStack {
            if(libraryPageGlobals.isLaunchingGame) {
                VStack {
                    ProgressView(label: {
                        Text("Launching \(libraryPageGlobals.selectedGame?.name ?? "'Unknown'")...")
                    })
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .background {
                        if (libraryPageGlobals.selectedGame?.headerImage != nil){
                            KFImage(URL(string: libraryPageGlobals.selectedGame!.headerImage))
                                .placeholder {
                                    ProgressView()
                                }
                                .resizable()
                                .scaledToFill()
                                .blur(radius: 10)
                                .opacity(0.4)
                        }
                    }
                }
                .background(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity).zIndex(10)
            }
            
            VStack {
                if (errorMessage != nil) {
                    Text("Error: \(errorMessage!)")
                        .lineLimit(1)
                        .foregroundStyle(.red)
                } else if (!isLoading && libraryPageGlobals.gamesMeta.isEmpty) {
                    VStack {
                        ContentUnavailableView {
                            Label("No Libraries found", systemImage: "gamecontroller")
                                .padding(.bottom)
                        } description: {
                            Text("No Steam libraries found.\nPlease add a Steam library folder.")
                            Button {
                                libraryPageGlobals.showOptions = true
                            } label: {
                                Label("Add Library", systemImage: "plus")
                            }
                        }
                        .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    GamesList(load: load)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $libraryPageGlobals.showOptions) {
                OptionsView(load: load)
            }
            .sheet(isPresented: $libraryPageGlobals.showDetailView) {
                Modal(showModal: $libraryPageGlobals.showDetailView, collapse: true, content:  {
                    GameDetailView(game: $libraryPageGlobals.selectedGame)
                })
            }
            .sheet(isPresented: $showAddCustomGameView) {
                Modal("Custom Game Editor", showModal: $showAddCustomGameView, scrollable: false)  {
                    CustomGameView(isPresented: $showAddCustomGameView)
                }
            }
            .overlay(alignment: .bottom) {
                HStack(alignment: .bottom) {
                    ProcyonToolbar(showAddCustomGameView: $showAddCustomGameView)
                    Spacer()
                    if (isLoading) {
                        LoadingProgress(progress: $progress)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .transition(.opacity)
                .background {
                    Rectangle()
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .overlay(.procyonAccent.mix(with: .black, by: 0.4).opacity(0.5))
                        .mask {
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black.opacity(0.0), location: 0.0), // top = transparent
                                    .init(color: .black.opacity(0.9), location: 0.5), // fade in
                                    .init(color: .black.opacity(1.0), location: 1.0)              // bottom = solid
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                }
            }
            .onAppear() {
                isLoading = true // fixes missing library issue
                try? FileManager.default.createDirectory(at: PROCYON_SUPPORT_FOLDER_URL.appendingPathComponent(DEFAULT_CXP_BOTTLES_FOLDER), withIntermediateDirectories: true)
                try? stripEnvsInCXBottleConfigFile(selectedBottle: appGlobals.selectedBottle)
                Task(priority: .background) {
                    await load()
                }
                mntObserver = MountObserver(
                    onMount: {
                        Task(priority: .background) {
                            await load()
                        }
                    },
                    onUnmount: {
                        Task(priority: .background) {
                            await load()
                        }
                    }
                )
            }
            .onDisappear {
                mntObserver = nil
            }
            .environmentObject(libraryPageGlobals)
        }
    }
    
    @MainActor
    private func load() async {
        isLoading = true
        defer {
            Task {
                isLoading = false
            }
        }
        progress = 0
        libraryPageGlobals.gamesMeta.removeAll()
        libraryPageGlobals.folders = getSteamFolderPaths()
        if libraryPageGlobals.folders.isEmpty {
            console.warn("There are no folders to scan.")
        } else {
            for folder in libraryPageGlobals.folders {
                let folderURL = URL(string: folder)!
                if (!libraryPageGlobals.gamesMeta.filter { $0.libraryFolder == folderURL }.isEmpty) {
                    console.log("skipping gamesMeta processing")
                    return // in memory cache just in case you disconnect/reconnect an external drive that has been scanned already
                }
                do {
                    let foldergamesMeta = try getGamesMeta(from: folderURL)
                    libraryPageGlobals.gamesMeta.append(contentsOf: foldergamesMeta)
                } catch {
                    console.error(String(reflecting: error))
                }
            }
        }
        do {
            if(!appGlobals.userID.isEmpty) {
                let ownedMeta = try await api
                    .fetchOwnedGamesIDs(userID: appGlobals.userID)
                    .map{
                        GamesMeta(appid: $0, installdir: "", bytesDownloaded: "0", BytesTodownload: "0")
                    }
                    .filter { owned in
                        !libraryPageGlobals.gamesMeta.contains(where: { $0.appid == owned.appid })
                    }
                libraryPageGlobals.gamesMeta.append(contentsOf: ownedMeta)
            }
        } catch {
            console.error("fetchOwnedGamesIDs \(String(reflecting: error))")
        }
        
        do {
            libraryPageGlobals.games = try await api.fetchGamesInfo(meta: libraryPageGlobals.gamesMeta, setProgress: { self.progress = $0 })
            progress = 100
        } catch {
            console.error("fetchGamesInfo \(String(reflecting: error))")
        }
    }
}

#Preview {
    ContentView()
}

