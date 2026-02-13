//
//  Options.swift
//  Procyon
//
//  Created by Italo Mandara on 31/01/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct OptionsView: View {
    @State var bottles = getAllBottles(CXPatched: true)
    @EnvironmentObject var appGlobals: AppGlobals
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    var deleteCache: () -> Void
    var load: () async -> Void
    
    var body: some View {
        Modal(
            showModal: $libraryPageGlobals.showOptions,
        ) {
            VStack (alignment: .center){
                Text("Options").padding(.vertical, 10)
                VStack(alignment: .leading) {
                    Text("Game libraries").padding(.horizontal, 10)
                    List {
                        ForEach(libraryPageGlobals.folders, id: \.self) {folder in
                            HStack{
                                Text(extractFolderNameRegex(folder))
                                Spacer()
                                Button(action: {
                                    removeSteamFolderPath(folder)
                                    libraryPageGlobals.folders = getSteamFolderPaths()
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
                            if libraryPageGlobals.folders.contains(url.absoluteString) {
                                console.log("\(url.absoluteString) folder exists!")
                                return
                            }
                            addSteamFolderPaths(url)
                            libraryPageGlobals.folders.append(url.absoluteString)
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
                Button(URL(string: appGlobals.cxAppPath ?? "")?.lastPathComponent ?? "Select a Crossover App...") {
                    if let url = openFolderSelectorPanel(type: .application) {
                        appGlobals.cxAppPath = url.relativePath
                        persistUsrDefOptionString(key: "cxAppPath", value: url.relativePath)
                    }
                }
                Picker("Select a bottle", selection: $appGlobals.selectedBottle) {
                    Text("No bottle selected").tag("")
                    ForEach(bottles, id: \.absoluteString) { bottle in
                        let text = bottle.pathComponents.suffix(2).joined(separator: "/")
                        Text(text).tag(bottle.absoluteString)
                    }
                }.onChange(of: appGlobals.selectedBottle) { oldValue, newValue in
                    if(newValue != nil && newValue != "") {
                        persistUsrDefOptionString(key: "selectedBottle", value: newValue!)
                    }
                }
                HStack {
                    Button(action: { deleteCache() }) {
                        Label("Delete cache", systemImage: "trash")
                    }
                    .cornerRadius(20)
                    Spacer()
                    Button(action: {
                        Task {
                            await load()
                        }
                        libraryPageGlobals.showOptions = false
                    }) {
                        Label("Reload Libraries", systemImage: "arrow.clockwise")
                    }
                    .cornerRadius(20)
                }
            }
            .frame(width: 300, height: 320)
            .padding()
        }
        .background(.accent.mix(with: .black, by: 0.6))
    }
}

#Preview {
    OptionsView(
        deleteCache: { },
        load: { },
    )
}

