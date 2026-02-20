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
            ToolbarItemGroup(placement: .principal) {
                HStack {
                    Button {
                        libraryPageGlobals.showOptions = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    
                    Button("Library") {
                        router.go(to: .library)
                    }
                    
                    Button("Profile") {
                        router.go(to: .profile)
                    }
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search Game...", text: $libraryPageGlobals.filter)
                            .textFieldStyle(.plain)
                            .disableAutocorrection(true)
                            .focusEffectDisabled()
                            .textFieldStyle(.plain)
                    }
                    HStack {
                        Image(systemName: "arrow.up.arrow.down.circle")
                        Picker("", selection: $libraryPageGlobals.sortBy) {
                            Text("Name").tag(SortingOptions.name)
                            Text("Release Date").tag(SortingOptions.releaseDate)
                        }.pickerStyle(.menu)
                    }
                    
                    Text("Showing \(libraryPageGlobals.filteredGames.count)/\(libraryPageGlobals.games.count)").font(Font.footnote).padding(.trailing)
                }
            }
        }
    }
}

