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
    @Binding var showDetailView: Bool
    @Binding var selectedGame: SteamGame?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items) { item in
                    GameThumbnail(item: item, showDetailView: $showDetailView, selectedGame: $selectedGame)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 60)
        }
    }
}

