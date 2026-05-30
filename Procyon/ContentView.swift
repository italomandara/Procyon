//
//  ContentView.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import SwiftUI
import Combine

enum AppRoute {
    case libraryPage
    case profilePage
}

final class Router: ObservableObject {
    @Published var route: AppRoute = .libraryPage

    // Convenience helpers if you like
    func go(to newRoute: AppRoute) {
        route = newRoute
    }
}

struct ContentView: View {
    @StateObject var router = Router()
    @StateObject var appGlobals = AppGlobals()
    
    var body: some View {
        Group {
            switch(router.route){
            case .libraryPage:
                LibraryPage()
            case .profilePage:
                Text("Profile Page")
            }
        }
        .animation(.easeInOut, value: router.route)
        .preferredColorScheme(.dark)
        .environmentObject(router)
        .environmentObject(appGlobals)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        .procyonAccent.mix(with: .black, by: 0.2),
                        .procyonAccent.mix(with: .black, by: 0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
            }
        )
        .onAppear() {
            if(!appGlobals.selectedBottle.isEmpty){
                appGlobals.userID = getSteamUserID(usingBottlePath: URL(string: appGlobals.selectedBottle)!, steamWinePath:appGlobals.steamWinePath) ?? ""
            }
        }
    }
}

#Preview {
    ContentView()
}

