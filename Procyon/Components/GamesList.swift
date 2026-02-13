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
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(libraryPageGlobals.filteredGames) { item in
                    GameThumbnail(item: item)
                }
            }
            .padding(.horizontal)
        }.safeAreaInset(edge: .bottom, spacing: nil) {
            Toolbar(showOptions: $libraryPageGlobals.showOptions).padding()
        }
    }
}

