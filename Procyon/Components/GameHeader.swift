//
//  GameHeader.swift
//  Procyon
//
//  Created by Italo Mandara on 05/02/2026.
//

import SwiftUI

struct GameHeader: View {
    @Binding var game: Game?
    @Binding var showDetailView: Bool
    @EnvironmentObject var appGlobals: AppGlobals
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    @EnvironmentObject var gameOptions: GameOptions
    @State private var showGameOptions: Bool = false
    
    var developers: String {
        "Developer: \(game?.developers.joined(separator: ", ") ?? ("Unknown Developer"))"
    }
    
    var publishers: String { // @To do: DRY
        "Publisher: \(game?.publishers.joined(separator: ", ") ?? ("Unknown Publisher"))"
    }
    
    var body: some View {
        let isNative = getMeta(libraryPageGlobals.gamesMeta, byID: String(game!.id))?.isNative ?? false
        
        HStack (alignment: .bottom) {
            VStack(alignment: .leading){
                Text(game!.name).font(.largeTitle.bold())
                Text(developers).font(.title2)
                Text(publishers).font(.title3)
            }
            BigButton(text: "Play", action: {
                libraryPageGlobals.setLoader(state: true)
                Task {
                    do {
                        
                        if(isNative) {
                            try await launchNativeGame(id: String(game!.steamAppID), cxAppPath: appGlobals.cxAppPath ?? "", selectedBottle: appGlobals.selectedBottle!, options: gameOptions)
                        } else {
                            try await launchWindowsGame(id: String(game!.steamAppID), cxAppPath: appGlobals.cxAppPath ?? "", selectedBottle: appGlobals.selectedBottle!, options: gameOptions)
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                            libraryPageGlobals.setLoader(state: false)
                        }
                    } catch {
                        libraryPageGlobals.setLoader(state: false)
                        console.warn("Error launching game: \(error)")
                    }
                    showDetailView = false
                }
            })
            .padding(.leading, 24)
            Spacer()
            HStack(alignment: .center) {
                Button {
                    showGameOptions = true
                } label: {
                    Image(systemName: "gear")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .foregroundStyle(.white)
                }.buttonStyle(.plain)
                Button {
                    let meta = getMeta(libraryPageGlobals.gamesMeta, byID: String(game!.id))!
                    showFolder(url: meta.gameURL!)
                } label: {
                    Image(systemName: "folder.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .foregroundStyle(.white)
                }.buttonStyle(.plain)
                if(isNative == true) {
                    Image(systemName: "apple.logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .foregroundStyle(.white)

                }
                if(game!.controllerSupport == "full") {
                    Image(systemName: "gamecontroller.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .foregroundStyle(.white)

                }
                HStack(alignment: .center){
                    Text("Available for:")
                    if (game!.platforms.mac) {
                        Image("os-apple")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                    }
                    if (game!.platforms.linux) {
                        Image("os-linux")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                    }
                    if (game!.platforms.windows) {
                        Image("os-win")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(.clear)
                .overlay(
                    Capsule()
                        .stroke(.white, lineWidth: 2)
                )
                .clipShape(.capsule)
            }
        }
        .foregroundStyle(.white)
        .sheet(isPresented: $showGameOptions) {
            Modal(showModal: $showGameOptions) {
                GameOptionsView(game: $game)
            }
        }
    }
}
