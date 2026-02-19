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
    @EnvironmentObject var appGlobals: AppGlobals
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    
    var body: some View {
        Button(action: {
            libraryPageGlobals.showDetailView =  true
            libraryPageGlobals.selectedGame = item
        }) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing){
                    KFImage(URL(string: item.headerImage))
                        .placeholder {
                            ProgressView()
                        }
                        .resizable()
                        .scaledToFit()
                    if (libraryPageGlobals.gamesMeta.first(where: { $0.appid == String(item.id) })!.isNative) {
                        Image("os-apple")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)              // icon size
                            .padding(8)                                // space inside the circle
                            .background(Color.black.opacity(0.5))     // semi-transparent black
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
                            libraryPageGlobals.selectedGame = item
                            libraryPageGlobals.setLoader(state: true)

                            Task {
                                do {
                                    let gameOptKey = namespacedKey("GameOptions", String(item.id))
                                    let gameOptions: GameOptions = GameOptions()
                                    if let gameOptionsData: GameOptionsData = readUsrDefData(key: gameOptKey) {
                                        let gameOptions: GameOptions = GameOptions()
                                        gameOptions.set(data: gameOptionsData)
                                    }
                                    let isNative = libraryPageGlobals.gamesMeta.first(where: { $0.appid == String(item.id) })?.isNative ?? false
                                    if(isNative) {
                                        try await launchNativeGame(id: String(item.id), cxAppPath: appGlobals.cxAppPath ?? "", selectedBottle: appGlobals.selectedBottle!, options: gameOptions)
                                    } else {
                                        try await launchWindowsGame(id: String(item.id), cxAppPath: appGlobals.cxAppPath ?? "", selectedBottle: appGlobals.selectedBottle!, options: gameOptions)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                                        libraryPageGlobals.setLoader(state: false)
                                    }
                                } catch {
                                    console.warn(error.localizedDescription)
                                    libraryPageGlobals.setLoader(state: false)
                                }
                            }
                        } label: {
                            Label("Play", systemImage: "play.fill")
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
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var showDetailView: Bool = false
    @Previewable @State var selectedGame: SteamGame? = nil
    GameThumbnail(item: SteamGame.mock)
}
