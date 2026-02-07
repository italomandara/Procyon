//
//  ContentView.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import SwiftUI
import Combine

enum AppRoute {
    case library
    case profile
}

final class Router: ObservableObject {
    @Published var route: AppRoute = .library

    // Convenience helpers if you like
    func go(to newRoute: AppRoute) {
        route = newRoute
    }
}

final class AppGlobals: ObservableObject {
    @Published var selectedBottle: String?
    @Published var cxAppPath: String?
    
    init(selectedBottle: String? = "", cxAppPath: String? = nil) {
        self.selectedBottle = readUsrDefOptionString(key: "selectedBottle")
        self.cxAppPath = readUsrDefOptionString(key: "cxAppPath")
    }
}

struct ContentView: View {
    @StateObject var router = Router()
    @StateObject var appGlobals = AppGlobals(
        selectedBottle: readUsrDefOptionString(key: "selectedBottle"),
        cxAppPath: readUsrDefOptionString(key: "cxAppPath"),
    )
    
    var body: some View {
        Group {
            switch(router.route){
            case .library:
                LibraryPage()
            case .profile:
                VStack() {
                    Text("Profile Page")
                    Button("Go to Library") {
                        router.go(to: .library)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environmentObject(router)
        .environmentObject(appGlobals)
        .animation(.default, value: router.route)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.60, green: 0.0, blue: 0.0),
                        Color(red: 0.35, green: 0.0, blue: 0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
                Image(.procyon)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.1)
                    .blendMode(.multiply)
                    .blur(radius: 20)
            }
        )
    }
}

#Preview {
    ContentView()
}

