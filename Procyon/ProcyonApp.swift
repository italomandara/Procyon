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

@main
struct ProcyonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: windowWidth, height: windowHeight)
        .windowResizability(.contentSize)
    }

}
