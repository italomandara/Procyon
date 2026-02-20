//
//  GameView.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import SwiftUI

let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible())
]

struct GamesList: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(libraryPageGlobals.filteredGames) { item in
                    GameThumbnail(item: item)
                }
            }
            .padding(.horizontal)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    libraryPageGlobals.showOptions = true
                } label: {
                    Image(systemName: "gear")
                }
            }
            ToolbarItemGroup(placement: .secondaryAction) {
                HStack{
                    Button("Library") {
                        router.go(to: .library)
                    }.controlSize(.small)
                    Divider()
                    Button("Profile") {
                        router.go(to: .profile)
                    }.controlSize(.small)
                }.padding(.horizontal)
            }
            ToolbarItemGroup(placement: .principal) {
                HStack {
                    HStack {
                        Button {
                            if (libraryPageGlobals.filter.isEmpty) {
                                return
                            } else {
                                libraryPageGlobals.filter = ""
                            }
                        } label: {
                            Image(systemName: libraryPageGlobals.filter.isEmpty ? "magnifyingglass": "xmark.circle")
                        }
                        .buttonStyle(.plain)
                        .controlSize(.small)
                        TextField("Search Game...", text: $libraryPageGlobals.filter)
                            .textFieldStyle(.plain)
                            .disableAutocorrection(true)
                            .focusEffectDisabled()
                            .textFieldStyle(.plain)
                            .frame(width: 100)
                            .controlSize(.small)
                    }
                    Divider()
                    HStack {
                        Image(systemName: "arrow.up.arrow.down.circle")
                        Picker("", selection: $libraryPageGlobals.sortBy) {
                            Text("Name").tag(SortingOptions.name)
                            Text("Release Date").tag(SortingOptions.releaseDate)
                        }
                        .pickerStyle(.menu)
                        .controlSize(.small)
                    }
                    Divider()
                    Text("Showing \(libraryPageGlobals.filteredGames.count)/\(libraryPageGlobals.games.count)").font(Font.footnote)
                }.padding(.horizontal)
            }
        }
    }
}

