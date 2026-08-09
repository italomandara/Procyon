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
    @Binding var game: Game?
    @State private var player = AVPlayer()
    @State private var isMuted: Bool = true
    
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    @StateObject var gameOptions = GameOptions()
    var gameFolder: String {
        let meta = getMeta(libraryPageGlobals.gamesMeta, byID: String(game!.id))!
        return meta.libraryFolder.appendingPathComponent(meta.installdir).path(percentEncoded: false)
    }
    
    var body: some View {
        if (game != nil) {
            VStack (alignment: .leading) {
                ZStack(alignment: .bottom ) {
                    if (game!.movies != nil && !game!.movies!.isEmpty) {
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
                                if !game!.headerImage.isEmpty { ProgressView() }
                            }
                            .onFailureView { Color.clear }
                            .resizable()
                            .scaledToFit()
                    }
                    GameHeader(game: $game, showDetailView: $libraryPageGlobals.showDetailView)
                        .padding(30)
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
                    HStack (alignment: .top){
                        VStack(alignment: .leading) {
                            Text(game!.detailedDescription).padding(.bottom)
                            
                            if(game!.contentDescriptors?.notes != nil){
                                Text(game!.contentDescriptors!.notes!).padding(.bottom)
                            }
                            
                            if(game!.pcRequirements != nil){
                                VStack(alignment: .leading) {
                                    Text("PC Requirements:").font(.title3).padding(.bottom, 5)
                                    RequirementsWidget(requirements: game!.pcRequirements)
                                }.padding(.bottom)
                            }
                            if(game!.macRequirements != nil){
                                VStack(alignment: .leading) {
                                    Text("Mac Requirements:").font(.title3).padding(.bottom, 5)
                                    RequirementsWidget(requirements:game!.macRequirements)
                                }.padding(.bottom)
                            }
                            if(game!.linuxRequirements != nil){
                                VStack(alignment: .leading) {
                                    Text("Linux Requirements:").font(.title3).padding(.bottom, 5)
                                    RequirementsWidget(requirements:game!.linuxRequirements)
                                }.padding(.bottom)
                            }
                        }.padding(.bottom).padding(.trailing, 20)
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Release date: \(game!.releaseDate.date)").padding(.bottom)
                            
                            HStack{
                                if (game!.isFree == true){
                                    AccentTag("Free to Play").padding(.bottom)
                                }
                                if (game!.requiredAge != "0"){
                                    AccentTag("Age: \(game!.requiredAge)+").padding(.bottom)
                                }
                            }
                            
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
                            
                            let languages: [String] = (game!.supportedLanguages ?? "")
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }

                            if !languages.isEmpty {
                                Text("Supported languages:")
                                HFlow(alignment: .center) {
                                    ForEach(Array(languages.enumerated()), id: \.offset) { pair in
                                        AccentTag(pair.element)
                                            .padding(.vertical, 0.5)
                                    }
                                }.padding(.bottom)
                            }
                            
                            if(game!.legalNotice != nil){
                                Text(game!.legalNotice!).font(.footnote).padding(.bottom, 5)
                            }
                            if(game!.supportInfo != nil) {
                                VStack(alignment: .leading) {
                                    Text("Support:").padding(.bottom, 2)
                                    if(game!.supportInfo!.url != nil && !game!.supportInfo!.url!.isEmpty){
                                        Text("Website: \(game!.supportInfo!.url!)").font(Font.footnote.italic()).padding(.bottom, 2)
                                    }
                                    if(game!.supportInfo!.email != nil && !game!.supportInfo!.email!.isEmpty){
                                        Text("Email: \(game!.supportInfo!.email!)").font(Font.footnote.italic()).padding(.bottom, 2)
                                    }
                                }.padding(.bottom, 5)
                            }
                        }.frame(width: 200)
                    }
                    
                    VStack (alignment: .leading) {
                        if(game!.screenshots != nil && game!.screenshots!.count > 0) {
                            Text("Screenshots:").font(.title2).padding(.top)
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
                            }
                        }
                        
                        if (game!.movies != nil) {
                            Text("Videos:").font(.title2).padding(.top)
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
                            
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, game!.movies == nil ? 30: -5)
                .padding(.bottom, 30)
            }
            .background(.accent.mix(with: .black, by: 0.6).opacity(0.9))
            .frame(width: windowWidth - 100)
            .environmentObject(gameOptions)
        }
    }
}

#Preview {
    @State @Previewable var game: Game? = .mock
    @State @Previewable var showDetailView: Bool = true
    
    ZStack (alignment: .topTrailing) {
        ScrollView {
            GameDetailView(game: $game)
        }
    }
}
    
