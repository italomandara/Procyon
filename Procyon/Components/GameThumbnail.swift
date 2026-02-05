//
//  GameThumbnail.swift
//  Procyon
//
//  Created by Italo Mandara on 30/01/2026.
//

import SwiftUI
import Kingfisher

struct GameThumbnail: View {
    let item: SteamGame
    @Binding var showDetailView: Bool
    @Binding var selectedGame: SteamGame?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing){
                KFImage(URL(string: item.headerImage))
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .scaledToFit()
                if(item.controllerSupport == "full") {
                    Image(systemName: "gamecontroller.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)              // icon size
                    .padding(4)                                // space inside the circle
                    .background(Color.black.opacity(0.9))     // semi-transparent black
                    .clipShape(Circle())                       // make it circular
                    .foregroundStyle(.white)                   // icon color
                    .padding(8)
                }
            }
            VStack (alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                HStack (spacing: 6){
                    AccentTag(item.type)
                    if (item.genres != nil && item.genres!.count > 0){
                        AccentTag(item.genres!.first!.description)
                    }
                    Spacer()
                    Button {
                        showDetailView =  true
                        selectedGame = item
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .font(.caption)
                    .cornerRadius(20)
                    Button {} label: {
                        Image(systemName: "play.fill")
                    }
                    .cornerRadius(20)
                }
                .padding(.bottom, 8)
            }.foregroundStyle(.white)
                .padding(.horizontal)
            }
        .background(.black.opacity(0.5))
        .cornerRadius(30)
    }
}

#Preview {
    @Previewable @State var showDetailView: Bool = false
    @Previewable @State var selectedGame: SteamGame? = nil
    GameThumbnail(item: SteamGame.mock, showDetailView: $showDetailView, selectedGame: $selectedGame)
}
