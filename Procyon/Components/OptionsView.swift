//
//  Options.swift
//  Procyon
//
//  Created by Italo Mandara on 31/01/2026.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct OptionsView: View {
    @State var bottles: [URL] = []
    @State var progress: Double = 0
    @State var progressLabel = "Processing..."
    @State var downloading: Bool = false
    @State var shouldShowBottleSelector: Bool = false
    @State var creatingBottle: Bool = false
    @EnvironmentObject var appGlobals: AppGlobals
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    @MainActor var load: @Sendable () async -> Void
    @State var createBtlPrc: Process?
    @State private var showSteamPathError: Bool = false

    // MARK: - Derived state

    private var hasCXApp: Bool {
        !appGlobals.cxAppPath.isEmpty
    }

    private var hasBottle: Bool {
        !appGlobals.selectedBottle.isEmpty
    }

    private var hasSteamPath: Bool {
        !appGlobals.steamWinePath.isEmpty
    }

    // MARK: - Body

    var body: some View {
        Modal(
            "Options",
            showModal: $libraryPageGlobals.showOptions
        ) {
            VStack(alignment: .leading) {

                // Step 1 — CX App selection (always visible)
                cxAppSection

                if downloading {
                    ProgressView(value: progress, total: 100) {
                        Text(progressLabel).font(.footnote)
                    }
                    .padding(.top)
                }

                // Step 1b & 2 — both require CX app
                if hasCXApp {
                    // Launch Crossover depends only on cxAppPath being set
                    ProminentButton("Launch Crossover", image: "crossover-fill") {
                        if !appGlobals.cxAppPath.isEmpty {
                            let url = URL(fileURLWithPath: appGlobals.cxAppPath)
                            let configuration = NSWorkspace.OpenConfiguration()
                            configuration.environment = [
                                "CX_GRAPHICS_BACKEND": CXGraphicsBackend.d3dmetal.rawValue,
                                "MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS": "0"
                            ]
                            NSWorkspace.shared.open(url, configuration: configuration)
                        }
                    }

                    bottleSection
                }

                // Step 3 — Game libraries + downstream options (requires bottle)
                if hasBottle {
                    GameLibrariesList(load: load)
                        .padding(.vertical)

                    steamPathSection

                    cacheSection
                }

                if DEBUG_ENABLED == true {
                    debugSection
                }
            }
            .frame(width: 300)
            .padding(.vertical)
        }
        .onAppear {
            let path = readUsrDefOptionString(key: "cxCompleteAppPath")
            if !path.isEmpty {
                console.log("loading paths for bottles")
                let f = FileManager.default
                if !f.fileExists(atPath: path) {
                    appGlobals.cxAppPath = ""
                }
                do {
                    bottles = try getAllBottles(appDir: URL(fileURLWithPath: path))
                } catch {
                    console.error(String(reflecting: error))
                }
                console.log(bottles.debugDescription)
            }
            if !bottles.isEmpty && hasCXApp {
                shouldShowBottleSelector = true
            }
        }
    }

    // MARK: - Sections

    /// Always visible. Lets the user pick a Crossover .app.
    @ViewBuilder
    private var cxAppSection: some View {
        Button(URL(string: appGlobals.cxAppPath)?.lastPathComponent ?? "Select a Crossover App...") {
            shouldShowBottleSelector = false
            if let url = openFolderSelectorPanel(type: UTType.application) {
                appGlobals.selectedBottle = ""
                do {
                    bottles = try getAllBottles(appDir: url)
                } catch {
                    console.error(String(reflecting: error))
                }
                Task { @MainActor in
                    let patchedAppURL = await makeCrossoverPatchedCopy(
                        sourceCXPath: url,
                        setProgress: { p, m in progress = p; progressLabel = m },
                        setLoading: { state in downloading = state }
                    )
                    progress = 0
                    await makeX87CrossoverPatchedCopy(sourceCXPath: url, patchedApp: patchedAppURL)
                    appGlobals.cxAppPath = patchedAppURL.path(percentEncoded: false)
                    persistUsrDefOptionString(key: "cxCompleteAppPath", value: patchedAppURL.path(percentEncoded: false))
                    shouldShowBottleSelector = !bottles.isEmpty
                }
            } else {
                shouldShowBottleSelector = !bottles.isEmpty
            }
        }
    }

    /// Visible when CX app is set. Shows bottle picker, empty state, or creation flow.
    @ViewBuilder
    private var bottleSection: some View {
        if shouldShowBottleSelector {
            Picker("Select a bottle", selection: $appGlobals.selectedBottle) {
                Text("No bottle selected").tag("")
                ForEach(bottles, id: \.absoluteString) { bottle in
                    let components = bottle.pathComponents
                    let lastTwo = Array(components.suffix(2))
                    let label = lastTwo.joined(separator: "/")
                    Text(label).tag(bottle.absoluteString)
                }
            }
            .onChange(of: appGlobals.selectedBottle) { oldValue, newValue in
                guard newValue.isEmpty == false else { return }
                libraryPageGlobals.folders.removeAll()
                resetPersistedFolderAccess()
                let steamLibrariesURLs = getSteamLibraryFolders(
                    from: URL(string: newValue)!,
                    appGlobals: appGlobals
                )
                steamLibrariesURLs.forEach { url in
                    validateAddSteamFolder(url, to: &libraryPageGlobals.folders)
                }
                let steamDir = URL(string: newValue)!
                    .appendingPathComponent(appGlobals.steamWinePath)
                if !appGlobals.steamWinePath.isEmpty {
                    var isDirectory: ObjCBool = false
                    let exists = FileManager.default.fileExists(
                        atPath: steamDir.path(percentEncoded: false),
                        isDirectory: &isDirectory
                    )
                    if !exists || !isDirectory.boolValue {
                        console.warn("Steam (Wine) path doesn't exist in the selected bottle. Resetting to default.")
                        appGlobals.steamWinePath = ""
                    }
                }
                Task { await load() }
            }
            if appGlobals.selectedBottle.isEmpty == false {
                ProminentButton("Open selected bottle", systemImage: "waterbottle") {
                    if let selectedBottleURL = URL(string: appGlobals.selectedBottle) {
                        showFolder(url: selectedBottleURL)
                    }
                }
            }
        } else if bottles.isEmpty {
            Text("No bottles found")
            Text("Create a new bottle first").font(.footnote)
            ProminentButton("Create new bottle", systemImage: "waterbottle") {
                guard !creatingBottle else {
                    if appGlobals.cxAppPath.isEmpty {
                        console.error("Can't create a bottle before CX app is selected")
                    }
                    return
                }
                creatingBottle = true
                createBtlPrc = try? createBottle(cxAppPath: appGlobals.cxAppPath)
                if let proc = createBtlPrc {
                    proc.terminationHandler = { _ in
                        DispatchQueue.main.async {
                            creatingBottle = false
                            let cxCompleteAppPath = readUsrDefOptionString(key: "cxCompleteAppPath")
                            if !cxCompleteAppPath.isEmpty {
                                do {
                                    bottles = try getAllBottles(appDir: URL(fileURLWithPath: cxCompleteAppPath))
                                    shouldShowBottleSelector = true
                                } catch {
                                    console.error(String(reflecting: error))
                                }
                            } else {
                                console.error("Failed to load all bottles")
                            }
                        }
                    }
                } else {
                    creatingBottle = false
                    console.error("Bottle creation failed")
                }
            }
            if creatingBottle {
                ProgressView().progressViewStyle(.linear).frame(maxWidth: .infinity)
                Button("Cancel") {
                    createBtlPrc?.terminate()
                    creatingBottle = false
                }
            }
        } else {
            ProgressView().progressViewStyle(.linear).frame(maxWidth: .infinity)
        }
    }

    /// Visible when a bottle is selected. Steam path depends on selectedBottle.
    @ViewBuilder
    private var steamPathSection: some View {
        Divider().padding(.top, 10)
        Text("Steam (Wine) install").padding(.vertical, 5)
        Button("Select Steam (Wine) install directory...") {
            guard let url = openFolderSelectorPanel(type: .folder, title: "Select Steam (Wine) install directory") else { return }
            guard let bottleURL = URL(string: appGlobals.selectedBottle),
                  let relativePath = relativePathInBottle(selected: url, bottle: bottleURL) else {
                showSteamPathError = true  // ← replace the commented block with this
                return
            }
            appGlobals.steamWinePath = relativePath
        }
        .alert("Invalid Steam Location", isPresented: $showSteamPathError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The Steam install folder must be located under the selected bottle. Please reselect the Steam install folder.")
        }
        
        if hasSteamPath {
            Text(appGlobals.steamWinePath)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            ProminentButton("Launch Steam UI", image: "steam-fill") {
                openSteam(
                    cxAppPath: appGlobals.cxAppPath,
                    selectedBottle: appGlobals.selectedBottle,
                    steamWinePath: appGlobals.steamWinePath
                )
            }
        }
    }

    /// Cache controls — visible whenever a bottle is selected.
    @ViewBuilder
    private var cacheSection: some View {
        Divider().padding(.top, 10)
        Text("Cache management").padding(.vertical, 5)
        ProminentButton("Delete Owned games cache", systemImage: "trash") {
            api.deleteOwnedGamesIDsCache()
            libraryPageGlobals.gamesMeta.removeAll()
            Task { await load() }
            libraryPageGlobals.showOptions = false
        }
        ProminentButton("Delete cache", systemImage: "trash") {
            api.deleteGameCache()
            api.deleteBlacklistCache()
            libraryPageGlobals.games.removeAll()
            Task { await load() }
            libraryPageGlobals.showOptions = false
        }
        ProminentButton("Delete all downloads cache", systemImage: "trash") {
            TarDownloader.deleteAllDownloadCache()
        }
    }

    /// Debug tools — gated by the global debug flag.
    @ViewBuilder
    private var debugSection: some View {
        Divider().padding(.top, 10)
        Text("Debug").padding(.vertical, 5)
        ProminentButton("Start Logging", systemImage: "ant") {
            console.enableLogFile = true
        }
        Spacer()
        ProminentButton("Download logs", systemImage: "square.and.arrow.down") {
            console.saveLogs()
        }
    }
}

private func relativePathInBottle(selected: URL, bottle: URL) -> String? {
    let bottlePath = bottle.standardizedFileURL.path(percentEncoded: false)
    let selectedPath = selected.standardizedFileURL.path(percentEncoded: false)
    guard selectedPath.hasPrefix(bottlePath) else { return nil }
    var remainder = String(selectedPath.dropFirst(bottlePath.count))
    guard !remainder.isEmpty else { return nil }
    if remainder.hasPrefix("/") {
        remainder = String(remainder.dropFirst())
    }
    return remainder.isEmpty ? nil : remainder
}

#Preview {
    OptionsView(load: { })
}
