//
//  AddEditCustomGameView.swift
//  Procyon
//
//  Created by Italo Mandara on 18/03/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct CustomGameView: View {
    @State private var text: String = ""
    @State private var game: Game = .emptyGame
    @State private var id: String = ""
    @State private var isAutofilling: Bool = false
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    @Binding var isPresented: Bool
    
    var customGames: [Game] {
        libraryPageGlobals.customAddedGames.filter { $0.isCustom == true }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 20) {
//                VStack{
                    GameThumbnail(item: game, isResizable: false)
//                }.frame(minWidth: 450)
                VStack(alignment: .leading, spacing: 15) {
                    Picker("Select a Game", selection: $id) {
                        Text("New Game").tag("")
                        ForEach(customGames, id: \.id) { game in
                            Text(game.name).tag(game.id)
                        }
                    }.onChange(of: id) {
                        if id != "" {
                            if let currentGame = libraryPageGlobals.getCustomAddedGame(id: id) {
                                game = currentGame
                            }
                        } else {
                            game = .emptyGame
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Game Title")
                        TextField("Game Title", text: $game.name)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Header Image URL")
                        TextField("Header Image URL", text: $game.headerImage)
                    }
                    // Executable path
                    Button(game.appExeURL?.lastPathComponent ?? "Select a Game App...") {
                        if let url = openFolderSelectorPanel(type: .executable) {
                            game.appExeURL = url
                            game.appNames.append(url.lastPathComponent)
                            game.isNative = url.pathExtension == "exe" ? false : true
                            if id == "" {
                                game.id = url.path(percentEncoded: false)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    if (AUTOFILL_CUSTOM_GAME_ENABLED && game.appExeURL != nil) {
                        HStack {
                            ProminentButton("Autofill Data", systemImage: "wand.and.sparkles") {
                                if let url = game.appExeURL {
                                    isAutofilling = true
                                    Task {
                                        let customGame = CustomGameAPI()
                                        let hint = url.path(percentEncoded: false)
                                        do {
                                            let fetchedGame = try await customGame.fetch(hints: hint)
                                            if fetchedGame != nil {
                                                game = fetchedGame!
                                            }
                                        } catch {
                                            console.error(String(reflecting: error))
                                        }
                                        game.headerImage = "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/\(game.steamAppID)/header.jpg"
                                        game.appExeURL = url
                                        game.appNames.append(url.lastPathComponent)
                                        game.isNative = url.pathExtension == "exe" ? false : true
                                        if id == "" {
                                            game.id = url.path(percentEncoded: false)
                                        }
                                        isAutofilling = false
                                    }
                                }
                            }
                            if(isAutofilling){
                                ProgressView().controlSize(.small)
                            }
                        }
                    }
                    Toggle("Is a Native Game", isOn: $game.isNative)
                    VStack(alignment: .leading){
                        Text("Supported Platforms")
                        HStack(spacing: 20) {
                            Toggle(isOn: $game.platforms.windows) {
                                Image("os-win")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 15)
                            }
                            Toggle(isOn: $game.platforms.mac) {
                                Image("os-apple")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 15)
                            }
                            Toggle(isOn: $game.platforms.linux) {
                                Image("os-linux")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 15)
                            }
                        }
                    }
                }
            }.frame(alignment: .top)
            // Descriptions
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Detailed Description")
                    TextField("Detailed Description", text: $game.detailedDescription, axis: .vertical)
                        .lineLimit(9...11)
                }
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("About The Game")
                        TextField("About The Game", text: $game.aboutTheGame, axis: .vertical)
                            .lineLimit(4...6)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Short Description")
                        TextField("Short Description", text: $game.shortDescription, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
            }
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Developers")
                    TextField(
                        "Developers (comma-separated)",
                        text: Binding(
                            get: { game.developers.joined(separator: ", ") },
                            set: { newValue in
                                game.developers = newValue
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            }
                        )
                    )
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Publishers")
                    TextField(
                        "Publishers (comma-separated)",
                        text: Binding(
                            get: { game.publishers.joined(separator: ", ") },
                            set: { newValue in
                                game.publishers = newValue
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            }
                        )
                    )
                }
            }
            // Categories as comma-separated by description
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Categories")
                    TextField(
                        "Categories (comma-separated descriptions)",
                        text: Binding(
                            get: { game.categories.map { $0.description }.joined(separator: ", ") },
                            set: { newValue in
                                let parts = newValue.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                var newCats: [Category] = []
                                for (idx, desc) in parts.enumerated() {
                                    if idx < game.categories.count {
                                        newCats.append(Category(id: game.categories[idx].id, description: desc))
                                    } else {
                                        newCats.append(Category(id: idx + 1, description: desc))
                                    }
                                }
                                game.categories = newCats
                            }
                        )
                    )
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Genres")
                    TextField(
                        "Genres (comma-separated descriptions)",
                        text: Binding(
                            get: { game.genres?.map { $0.description }.joined(separator: ", ") ?? "" },
                            set: { newValue in
                                let parts = newValue.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                var newGenre: [Genre] = []
                                for (idx, desc) in parts.enumerated() {
                                    if game.genres != nil && idx < game.genres?.count ?? 0 {
                                        newGenre.append(Genre(id: game.genres![idx].id, description: desc))
                                    } else {
                                        newGenre.append(Genre(id: String(idx + 1), description: desc))
                                    }
                                }
                                game.genres = newGenre
                            }
                        )
                    )
                }
            }
            Group {
                if id != "" {
                    ProminentButton("Update Game", systemImage: "arrow.2.circlepath") {
                        libraryPageGlobals.updateCustomAddedGames(gameData: game)
                        isPresented = false
                    }
                } else {
                    ProminentButton("Add Game", systemImage: "plus.circle") {
                        game.isCustom = true
                        libraryPageGlobals.customAddedGames.append(game)
                        libraryPageGlobals.saveCustomAddedGames()
                        isPresented = false
                    }
                }
            }
        }
        .padding(.vertical)
        .frame(width: 700)
    }
}

