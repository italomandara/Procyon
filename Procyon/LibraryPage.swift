//
//  LibraryPage.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import SwiftUI
import Combine
import Kingfisher

class LibraryPageGlobals: ObservableObject {
    @Published var appIDs: [String] = []
    @Published var folders: [String] = []
    @Published var showOptions: Bool = false
    @Published var filter: String = ""
    @Published var showDetailView = false
    @Published var selectedGame: SteamGame? = nil
    @Published var isLaunchingGame: Bool = false
    
    func setLoader(state: Bool) {
        isLaunchingGame = state
    }
}

struct LibraryPage: View {
    @StateObject var libraryPageGlobals = LibraryPageGlobals()
    @State private var items: [SteamGame] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var progress: Double = 0
    @State private var selectedGame: SteamGame? = nil
    @State private var mntObserver: MountObserver?
    
    private var api = SteamAPI()
    var filteredItems: [SteamGame] {
        items.filter { item in
            libraryPageGlobals.filter.isEmpty ||
            item.name.lowercased().contains(libraryPageGlobals.filter.lowercased())
        }
    }
    
    var body: some View {
        Group {
            VStack(alignment: .center) {
                if(libraryPageGlobals.isLaunchingGame) {
                    ProgressView(label: {
                        Text("Launching \(libraryPageGlobals.selectedGame?.name ?? "'Unknown'")...")
                    })
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .background {
//                            if (libraryPageGlobals.selectedGame?.headerImage != nil){
//                                KFImage(URL(string: libraryPageGlobals.selectedGame!.headerImage))
//                                    .placeholder {
//                                        ProgressView()
//                                    }
//                                    .resizable()
//                                    .scaledToFill()
//                                    .blur(radius: 10)
//                            }
//                        }
                } else if (isLoading) {
                    ZStack{
                        VStack(alignment: .center) {
                            Image(.procyon).resizable()
                                .scaledToFit()
                                .frame(width: 100)
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
                } else {
                    if (libraryPageGlobals.appIDs.isEmpty) {
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
                        GamesList(items: items)
                    }
                }
            }
            .sheet(isPresented: $libraryPageGlobals.showOptions) {
                OptionsView(deleteCache: api.deleteCache, load: load)
            }
            .sheet(isPresented: $libraryPageGlobals.showDetailView) {
                Modal(showModal: $libraryPageGlobals.showDetailView) {
                    GameDetailView(game: $libraryPageGlobals.selectedGame)
                }
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
        }.environmentObject(libraryPageGlobals)
    }
    
    @MainActor
    private func load() async {
        isLoading = true
        progress = 0
        libraryPageGlobals.appIDs.removeAll()
        do {
            libraryPageGlobals.folders = getSteamFolderPaths()
            if libraryPageGlobals.folders.isEmpty {
                print("There are no folders to scan.")
            } else {
                for folder in libraryPageGlobals.folders {
                    let games = try scanSteamFolder(dest: URL(string: folder)!)
                    libraryPageGlobals.appIDs.append(contentsOf: games)
                }
            }
        } catch {
            print(error)
        }

        defer {
            isLoading = false
        }
        
        do {
            items = try await api.fetchGamesInfo(appIDs: libraryPageGlobals.appIDs, setProgress: { self.progress = $0 })
            progress = 100
        } catch {
            errorMessage = error.localizedDescription
            print(error)
        }
    }
}

#Preview {
    ContentView()
}

