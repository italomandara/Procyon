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
    let items: [SteamGame]
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    var processedItems: [SteamGame] {
        items.filter { item in
            libraryPageGlobals.filter.isEmpty ||
            item.name.lowercased().contains(libraryPageGlobals.filter.lowercased())
        }.sorted { lhs, rhs in
            lhs.name.lowercased() < rhs.name.lowercased()
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(processedItems) { item in
                    GameThumbnail(item: item)
                }
            }
            .padding(.horizontal)
        }.safeAreaInset(edge: .bottom, spacing: nil) {
            Toolbar(showOptions: $libraryPageGlobals.showOptions).padding()
        }
//        Text("Viewing \(processedItems.count) of \(items.count) results").foregroundStyle(.white)
    }
}

