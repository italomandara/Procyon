//
//  ProcyonApp.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import SwiftUI
import CoreData

let windowWidth: CGFloat = 1024
let windowHeight: CGFloat = 750
let appWindowResizable: Bool = false

@main
struct ProcyonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: appWindowResizable ? nil : windowWidth, height: appWindowResizable ? nil : windowHeight)
        }
//        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
//        .windowToolbarLabelStyle(fixed: .iconOnly)
        .defaultSize(width: windowWidth, height: windowHeight)
        .windowResizability(.contentSize)
    }

}
