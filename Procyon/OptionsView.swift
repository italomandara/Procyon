//
//  Options.swift
//  Procyon
//
//  Created by Italo Mandara on 31/01/2026.
//

import SwiftUI

struct OptionsView: View {
    @Binding var showOptions: Bool
    @Binding var appIDS: [String]
    @Binding var folders: [String]
    var api: SteamAPI
    var load: () async -> Void
    
    var body: some View {
        Modal(
            showModal: $showOptions,
        ) {
            VStack (alignment: .center){
                Text("Options")
                Button(action: {
                    if let url = openFolderSelectorPanel() {
                        addSteamFolderPaths(url)
                        folders.append(url.path)
                        Task { await load() }
                    }
                }) {
                    Label("Add a steam library", systemImage: "gamecontroller")
                }
                ForEach(folders, id: \.self) {folder in
                    HStack{
                        Button("Remove") {
                            removeSteamFolderPath(folder)
                            folders = getSteamFolderPaths()
                            Task { await load() }
                        }
                        Text(folder)
                    }
                }
                Button(action: { api.deleteCache() }) {
                    Label("Delete cache", systemImage: "trash")
                }
                .cornerRadius(20)
                Button(action: { Task { await load() } }) {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .cornerRadius(20)
            }
            .frame(width: 300, height: 300)
            .padding()
        }
    }
}

#Preview {
    // Stub implementations for preview
    @State @Previewable var show = true
    @State @Previewable var appIDS: [String] = []
    @State @Previewable var folders : [String] = ["/example/path"]
    
    OptionsView(
        showOptions: .constant(true),
        appIDS: $appIDS,
        folders: $folders,
        api: SteamAPI(),
        load: { },
    )
}

