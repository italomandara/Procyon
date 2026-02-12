//
//  GameView.swift
//  Procyon
//
//  Created by Italo Mandara on 31/01/2026.
//

import SwiftUI
import Kingfisher
import Flow
import AVKit

struct GameDetailView: View {
    @Binding var game: SteamGame?
    @State private var player = AVPlayer()
    @State private var isMuted: Bool = true
//    @Binding var showDetailView: Bool
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    @StateObject var gameOptions = GameOptions()
    
    var body: some View {        
        if (game != nil) {
            VStack (alignment: .leading) {
                ZStack(alignment: .bottom ) {
                    if (game!.movies != nil) {
                        PlayerLayerView(player: player)
                            .ignoresSafeArea()
                            .frame(height: 540)
                            .position(x: 460, y: 260)
                            .onAppear {
                                let url = URL(string: game!.movies![0].hlsH264!)!
                                player = AVPlayer(url: url)
                                player.isMuted = true
                                player.play()
                            }
                            .onDisappear {
                                player.pause()
                            }
                    } else {
                        KFImage(URL(string: game!.headerImage))
                            .placeholder {
                                ProgressView()
                            }
                            .resizable()
                            .scaledToFit()
                    }
                    GameHeader(game: $game, showDetailView: $libraryPageGlobals.showDetailView)
                        .padding()
                        .padding(.top, 40)
                        .background(
                            LinearGradient(
                                colors: [
                                    .black.opacity(0),
                                    .black.opacity(0.8),
                                    .black.opacity(1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.bottom, game!.movies != nil ? 20 : 0)
                }
                VStack (alignment: .leading) {
                    if (game!.genres != nil && game!.genres!.count > 0){
                        Text("Genre:")
                        HFlow(alignment: .center) {
                            ForEach(game!.genres!, id: \.id) { genre in
                                Tag(genre.description)
                                    .padding(.vertical, 0.5)
                            }
                        }
                        .padding(.bottom)
                    }
                    
                    if (game!.categories.count > 0){
                        Text("Category:")
                        HFlow(alignment: .center) {
                            ForEach(game!.categories, id: \.id) { category in
                                Tag(category.description)
                                    .padding(.vertical, 0.5)
                            }
                        }
                        .padding(.bottom)
                    }
                    Text(game!.detailedDescription)
                        .padding(.bottom)
                    
                    if(game!.screenshots != nil && game!.screenshots!.count > 0) {
                        Text("Screenshots:").font(.title2)
                        LazyVGrid(columns: [
                            GridItem(.flexible(maximum: .infinity)),
                            GridItem(.flexible(maximum: .infinity)),
                            GridItem(.flexible(maximum: .infinity))
                        ]) {
                            ForEach(game!.screenshots!, id: \.id) { screenshot in
                                KFImage(URL(string: screenshot.pathThumbnail))
                                    .placeholder {
                                        ProgressView()
                                    }
                                    .resizable()
                                    .scaledToFit()
//                                    .frame(width: 180, height: 100)
                            }
                        }.padding(.bottom)
                    }
                    if (game!.movies != nil) {
                        Text("Videos:").font(.title2)
                        LazyVGrid(columns: [
                            GridItem(.flexible(maximum: .infinity)),
                            GridItem(.flexible(maximum: .infinity)),
                            GridItem(.flexible(maximum: .infinity))
                        ]) {
                            ForEach(game!.movies!, id: \.id) { movie in
                                KFImage(URL(string: movie.thumbnail))
                                    .placeholder {
                                        ProgressView()
                                    }
                                    .resizable()
                                    .scaledToFit()
//                                    .frame(width: 180, height: 100)
                            }
                        }
                        .padding(.bottom)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, game!.movies == nil ? 20: -15)
                .padding(.bottom, 20)
            }
            .frame(width: windowWidth - 100)
            .environmentObject(gameOptions)
        }
    }
}

#Preview {
    @State @Previewable var game: SteamGame? = .mock
    @State @Previewable var showDetailView: Bool = true
    
    ZStack (alignment: .topTrailing) {
        ScrollView {
            GameDetailView(game: $game)
        }
    }
}
    
