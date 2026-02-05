//
//  ContentView.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import SwiftUI
let windowWidth: CGFloat = 1024
let windowHeight: CGFloat = 750

struct ContentView: View {
    @State private var items: [SteamGame] = []
    @State private var appIDs: [String] = []
    @State private var folders: [String] = []
    @State private var isLoading = false
    @State private var showOptions = false
    @State private var showDetailView = false
    @State private var errorMessage: String?
    @State private var filter: String = ""
    @State private var progress: Double = 0
    @State private var progressPollTask: Task<Void, Never>? = nil
    @State private var selectedGame: SteamGame? = nil
    
    private var api = SteamAPI()
    
    var body: some View {
        VStack(alignment: .center) {
            if (isLoading) {
                ZStack{
                    Image(.procyon).resizable()
                        .scaledToFill().blendMode(.multiply).opacity(0.1)
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
                }.frame(width: windowWidth, height: windowHeight)
            } else if let errorMessage {
                Text("Error: \(errorMessage)")
                    .lineLimit(1)
                    .foregroundStyle(.red)
                    .frame(width: windowWidth, height: windowHeight)
            } else {
                ZStack(alignment: .bottom)  {
                    if (appIDs.isEmpty) {
                        ContentUnavailableView {
                            Label("No Libraries found", systemImage: "gamecontroller")
                        } description: {
                            Text("No Steam libraries found.\nPlease add a Steam library folder.")
                        }
                            .foregroundStyle(.white)
                            .frame(width: windowWidth, height: windowHeight)
                    } else {
                        GamesList(items: items.filter { item in
                            filter.isEmpty ||
                            item.name.lowercased().contains(filter.lowercased())
                        }, showDetailView: $showDetailView, selectedGame: $selectedGame)
                    }
                    Toolbar(filter: $filter, showOptions: $showOptions).padding(.bottom)
                }
            }
        }
        .sheet(isPresented: $showOptions) {
            OptionsView(showOptions: $showOptions, appIDS: $appIDs, folders: $folders, api: api, load: load)
        }
        .sheet(isPresented: $showDetailView) {
            Modal(showModal: $showDetailView) {
                GameDetailView(game: $selectedGame, showDetailView: $showDetailView)
            }
        }
        .task { await load() }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.60, green: 0.0, blue: 0.0),
                    Color(red: 0.35, green: 0.0, blue: 0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(width: windowWidth, height: windowHeight)
        .fixedSize()
        .transition(.opacity)
        .onDisappear {
            progressPollTask?.cancel()
            progressPollTask = nil
        }
    }
    @MainActor
    private func load() async {
        isLoading = true
        progress = 0
        appIDs.removeAll()
        do {
            folders = getSteamFolderPaths()
            if folders.isEmpty {
                print("There are no folders to scan.")
            } else {
                for folder in folders {
                    let games = try scanSteamFolder(dest: URL(string: folder)!)
                    appIDs.append(contentsOf: games)
                }
            }
        } catch {
            print(error)
        }
        progressPollTask?.cancel()
        progressPollTask = Task { @MainActor in
            while !Task.isCancelled {
                self.progress = api.progress
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        defer {
            progressPollTask?.cancel()
            progressPollTask = nil
            isLoading = false
        }
        do {
            items = try await api.fetchGamesInfo(appIDs: appIDs)
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

