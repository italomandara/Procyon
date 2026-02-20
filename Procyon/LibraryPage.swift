//
//  LibraryPage.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import SwiftUI
import Combine
import Kingfisher

enum SortingOptions {
    case name
    case releaseDate
}

class LibraryPageGlobals: ObservableObject {
    @Published var gamesMeta: [GamesMeta] = []
    @Published var folders: [String] = []
    @Published var showOptions: Bool = false
    @Published var filter: String = ""
    @Published var showDetailView = false
    @Published var selectedGame: Game? = nil
    @Published var isLaunchingGame: Bool = false
    @Published var games: [Game] = []
    @Published var sortBy: SortingOptions = SortingOptions.name
    
    var filteredGames: [Game] {
        self.games.filter { item in
            self.filter.isEmpty ||
            item.name.lowercased().contains(self.filter.lowercased())
        }.sorted { lhs, rhs in
            switch self.sortBy {
            case SortingOptions.name:
                return lhs.name.lowercased() < rhs.name.lowercased()
            case SortingOptions.releaseDate:
                return lhs.releaseDate.date < rhs.releaseDate.date
            }
        }
    }
    
    func setLoader(state: Bool) {
        isLaunchingGame = state
    }
}

struct LibraryPage: View {
    @StateObject var libraryPageGlobals = LibraryPageGlobals()
//    @State private var items: [SteamGame] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var progress: Double = 0
    @State private var selectedGame: SteamGame? = nil
    @State private var mntObserver: MountObserver?

    private var api = SteamAPI()
    
    var body: some View {
        Group {
            VStack(alignment: .center) {
                if(libraryPageGlobals.isLaunchingGame) {
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
                                .blendMode(.multiply)
                        }
                    }
                } else if (isLoading) {
                    ZStack{
                        VStack(alignment: .center) {
                            Image(.procyon).resizable()
                                .scaledToFit()
                                .frame(width: 80)
                            Text("Building your library…")
                                .foregroundStyle(.white)
                                .padding(.top)
                            ProgressView(value: progress, total: 100)
                                .progressViewStyle(.linear)
                                .frame(width: 200, alignment: .center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else if let errorMessage {
                    Text("Error: \(errorMessage)")
                        .lineLimit(1)
                        .foregroundStyle(.red)
                } else if (libraryPageGlobals.gamesMeta.isEmpty) {
                    VStack {
                        ContentUnavailableView {
                            Label("No Libraries found", systemImage: "gamecontroller")
                                .padding(.bottom)
                            Button {
                                libraryPageGlobals.showOptions = true
                            } label: {
                                Label("Add Library", systemImage: "plus")
                            }
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
                    GamesList()
                }
            }
            .sheet(isPresented: $libraryPageGlobals.showOptions) {
                OptionsView(deleteCache: api.deleteCache, load: load)
            }
            .sheet(isPresented: $libraryPageGlobals.showDetailView) {
                Modal(showModal: $libraryPageGlobals.showDetailView, collapse: true, content:  {
                    GameDetailView(game: $libraryPageGlobals.selectedGame)
                })
            }
            .task { await load() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .onAppear() {
                mntObserver = MountObserver(
                    onMount: {
                        Task {
                            await load()
                        }
                    },
                    onUnmount: {
                        Task {
                            await load()
                        }
                    }
                )
            }
            .onDisappear {
                mntObserver = nil
            }
        }
        .environmentObject(libraryPageGlobals)
    }
    
    @MainActor
    private func load() async {
        isLoading = true
        progress = 0
        libraryPageGlobals.gamesMeta.removeAll()
        do {
            libraryPageGlobals.folders = getSteamFolderPaths()
            if libraryPageGlobals.folders.isEmpty {
                console.warn("There are no folders to scan.")
            } else {
                for folder in libraryPageGlobals.folders {
                    let folderURL = URL(string: folder)!
                    if (!libraryPageGlobals.gamesMeta.filter { $0.libraryFolder == folderURL }.isEmpty) {
                        return // in memory cache just in case you disconnect/reconnect an external drive that has been scanned already
                    }
                    do {
                        let foldergamesMeta = try getGamesMeta(from: folderURL)
                        console.log("found \(foldergamesMeta.count) games in the current folder")
                        libraryPageGlobals.gamesMeta.append(contentsOf: foldergamesMeta)
                    } catch {
                        console.error(error.localizedDescription)
                    }
                }
            }
        }
        defer {
            isLoading = false
        }
        
        do {
            libraryPageGlobals.games = try await api.fetchGamesInfo(meta: libraryPageGlobals.gamesMeta, setProgress: { self.progress = $0 })
//            Task {
//                while progress <= 100 {
//                    try await Task.sleep(nanoseconds: 100_000_000)
//                    progress += 1
//                }
//            }
//            libraryPageGlobals.games = try await api.fetchGameInfoArray(appIDs: libraryPageGlobals.appIDs, setProgress: { self.progress = $0 })
            progress = 100
        } catch {
            errorMessage = error.localizedDescription
            console.error(error.localizedDescription)
        }
    }
}

#Preview {
    ContentView()
}

