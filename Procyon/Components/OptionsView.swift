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
                Spacer()
                VStack(alignment: .leading) {
                    Text("Game libraries").padding(.horizontal, 10)
                    List {
                        ForEach(folders, id: \.self) {folder in
                            HStack{
                                Text(extractFolderNameRegex(folder))
                                Spacer()
                                Button(action: {
                                    removeSteamFolderPath(folder)
                                    folders = getSteamFolderPaths()
                                    Task { await load() }
                                }) {
                                    Image(systemName: "trash")
                                }.buttonStyle(.borderless)
                            }
                        }
                    }
                    .listStyle(.bordered)
                    .frame(height: 100)
                    Button(action: {
                        if let url = openFolderSelectorPanel() {
                            addSteamFolderPaths(url)
                            folders.append(url.path)
                            Task { await load() }
                        }
                    }) {
                        Label("Add a steam library", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                    .padding(.horizontal, 10)
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                    .stroke(.gray)
                )
                .padding(.bottom)
                Spacer()
                HStack {
                    Button(action: { api.deleteCache() }) {
                        Label("Delete cache", systemImage: "trash")
                    }
                    .cornerRadius(20)
                    Spacer()
                    Button(action: { Task { await load() } }) {
                        Label("Reload Libraries", systemImage: "arrow.clockwise")
                    }
                    .cornerRadius(20)
                }
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
    @State @Previewable var folders : [String] = ["/example/path", "/example/path", "/example/path", "/example/path"]
    
    OptionsView(
        showOptions: .constant(true),
        appIDS: $appIDS,
        folders: $folders,
        api: SteamAPI(),
        load: { },
    )
}

