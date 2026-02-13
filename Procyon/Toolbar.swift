//
//  Toolbar.swift
//  Procyon
//
//  Created by Italo Mandara on 30/01/2026.
//

import SwiftUI

struct Toolbar: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    @Binding var showOptions: Bool
    
    var body: some View
    {
        HStack {
            Button {
                showOptions = true
            } label: {
                Image(systemName: "gear")
            }
            .frame(width: 25)
            .cornerRadius(20)
//            Button("Store") {
//            }.cornerRadius(20)
            Button("Library") {
                router.go(to: .library)
            }.cornerRadius(20)
            Button("Profile") {
                router.go(to: .profile)
            }.cornerRadius(20)

            TextField("Search Game...", text: $libraryPageGlobals.filter)
                .textFieldStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(width: 100)
                .background(.white.opacity(0.2))
                .foregroundStyle(.white)
                .cornerRadius(20)
                .disableAutocorrection(true)
                .focusEffectDisabled()
            
            Picker(selection: $libraryPageGlobals.sortBy) {
                Text("Name").tag(SortingOptions.name)
                Text("Release Date").tag(SortingOptions.releaseDate)
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 0)
            .background(.white.opacity(0.2))
            .foregroundStyle(.white)
            .cornerRadius(20)
            Text("Showing \(libraryPageGlobals.filteredGames.count)/\(libraryPageGlobals.games.count)").font(Font.footnote)
        }
        .padding(6)
        .background(.black.opacity(0.9))
        .foregroundStyle(.white)
        .cornerRadius(20)
    }
}

#if DEBUG
private struct Toolbar_PreviewsWrapper: View {
    @State private var showOptions = false
    @StateObject private var router = Router()
    @StateObject private var libraryPageGlobals = LibraryPageGlobals()

    var body: some View {
        Toolbar(showOptions: $showOptions)
            .environmentObject(router)
            .environmentObject(libraryPageGlobals)
            .padding()
            .background(Color.gray.opacity(0.2))
    }
}

#Preview("Toolbar") {
    Toolbar_PreviewsWrapper()
}
#endif

