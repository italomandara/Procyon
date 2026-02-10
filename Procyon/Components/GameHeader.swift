//
//  GameHeader.swift
//  Procyon
//
//  Created by Italo Mandara on 05/02/2026.
//

import SwiftUI

struct GameHeader: View {
    @Binding var game: SteamGame?
    @Binding var showDetailView: Bool
    @EnvironmentObject var appGlobals: AppGlobals
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    @EnvironmentObject var gameOptions: GameOptions
    
    var developers: String {
        "Developer: \(game?.developers.joined(separator: ", ") ?? ("Unknown Developer"))"
    }
    
    var publishers: String { // @To do: DRY
        "Publisher: \(game?.publishers.joined(separator: ", ") ?? ("Unknown Publisher"))"
    }
    
    var body: some View {
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
                        try await launchWindowsGame( id: String(game!.id), cxAppPath: appGlobals.cxAppPath ?? "", selectedBottle: appGlobals.selectedBottle!, options: gameOptions)
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
            .padding(.horizontal, 24)
            Spacer()
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
        }.foregroundStyle(.white)
    }
}
