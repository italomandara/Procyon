//
//  GameOptionsView.swift
//  Procyon
//
//  Created by Italo Mandara on 12/02/2026.
//

import SwiftUI

struct GameOptionsView: View {
    @Binding var game: Game?
    @EnvironmentObject var gameOptions: GameOptions
    @EnvironmentObject var appGlobals: AppGlobals
    
    var preferredMaxFrameRate: String {
        $gameOptions.dxmtPreferredMaxFrameRate.wrappedValue < 20.0 ? "Disabled" : "\($gameOptions.dxmtPreferredMaxFrameRate.wrappedValue)"
    }
    
    var body: some View {
        let id = game!.steamAppID != 0 ? String(describing: game!.steamAppID) : String(describing: game!.id)
        let gameOptKey = namespacedKey("GameOptions", id)
        VStack (alignment: .leading, spacing: 5){
            Text("Options for \(game!.name) id:\(id)").font(Font.footnote).foregroundStyle(.procyonBrightGray)
            Form {
                VStack(alignment: .leading, spacing: 20) {
                    Section("Generic options") {
                        HStack(alignment: .top, spacing: 20) {
                            VStack(alignment: .trailing){
                                Picker("Graphics Backend", selection: $gameOptions.cxGraphicsBackend) {
                                    Text("D3DMetal")
                                        .tag("d3dmetal")
                                    Text("DXMT")
                                        .tag("dxmt")
                                }
                                .pickerStyle(.menu)
                                Divider()
                                TextField("Game arguments", text: $gameOptions.gameArguments)
                                TextField("Env variables", text: $gameOptions.envVariables)
                                Divider()
                                Toggle("Use X87 Patch (32 bits only)", isOn: $gameOptions.x87PatchEnabled)
                                Toggle("Use DX9 Patch", isOn: $gameOptions.dx9PatchEnabled).onChange(of: gameOptions.dx9PatchEnabled) {
                                    if(gameOptions.dx9PatchEnabled && !gameOptions.envVariables.contains("MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS=1 DXVK_ASYNC=1 WINEDLLOVERRIDES=d3d9=n,b;d3d8=n,b")) {
                                        gameOptions.envVariables = "MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS=1 DXVK_ASYNC=1 WINEDLLOVERRIDES=d3d9=n,b;d3d8=n,b"
                                    }
                                    if(!gameOptions.dx9PatchEnabled && gameOptions.envVariables.contains("MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS=1 DXVK_ASYNC=1 WINEDLLOVERRIDES=d3d9=n,b;d3d8=n,b")) {
                                        gameOptions.envVariables = ""
                                    }
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Toggle("MSync", isOn: $gameOptions.wineMSync)
                                Toggle("Metal HUD", isOn: $gameOptions.mtlHudEnabled)
                                Toggle("Advertise AVX", isOn: $gameOptions.advertiseAVX)
                                Toggle("Enable SDL", isOn: $gameOptions.enableSDL)
                                Toggle("Disable Hidraw", isOn: $gameOptions.disableHidraw)
                            }
                        }
                    }
                    if(gameOptions.cxGraphicsBackend == "dxmt") {
                        Divider()
                        Section("DXMT Options") {
                            VStack{
                                Text(localizedString(forKey: "preferredMaxFrameRate", value: preferredMaxFrameRate))
                                Slider(
                                    value: $gameOptions.dxmtPreferredMaxFrameRate,
                                    in: 19...240,
                                    step: 1.0
                                )
                                .help(localizedString(forKey: "preferredMaxFrameRateHelp"))
                            }
                            
                            Toggle("metalFXSpatial", isOn: $gameOptions.dxmtMetalFXSpatial)
                                .help(localizedString(forKey: "metalFXSpatialHelp"))
                                .onChange(of: gameOptions.dxmtMetalFXSpatial) { oldValue, newValue in
                                    if (!newValue) {
                                        $gameOptions.dxmtMetalSpatialUpscaleFactor.wrappedValue = 1.0
                                    }
                                }
                            
                            if (gameOptions.dxmtMetalFXSpatial) {
                                VStack {
                                    Text(localizedString(forKey:"metalSpatialUpscaleFactor", value: String($gameOptions.dxmtMetalSpatialUpscaleFactor.wrappedValue)))
                                    Slider(
                                        value: $gameOptions.dxmtMetalSpatialUpscaleFactor,
                                        in: 1.0...2.0,
                                        step: 0.125
                                    )
                                    .help(localizedString(forKey: "metalFXSpatialHelp"))
                                }
                            }
                        }
                    }
                    if(!game!.isNative) {
                        Divider()
                        Section("Resolution (Virtual Desktop)") {
                            Toggle("Enable Virtual Desktop", isOn: $gameOptions.virtualDesktopEnabled)
                            if(gameOptions.virtualDesktopEnabled) {
                                TextField("Resolution (e.g. 1920x1080)", text: $gameOptions.virtualDesktopResolution)
                                HStack {
                                    ForEach(BottleResolutionManager.detectDisplayProfiles(), id: \.id) { profile in
                                        Button("\(profile.name) (\(profile.resolution))") {
                                            gameOptions.virtualDesktopResolution = profile.resolution
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                    }
                    HStack {
                        Button("Save settings") {
                            console.log("saving")
                            persistUsrDefData(key: gameOptKey, data: GameOptionsData(data: gameOptions))
                        }.buttonStyle(.borderedProminent)
//                        Button("Undo") {
//                            console.log("resetting")
//                            if let data: GameOptionsData = readUsrDefData(key: gameOptKey) {
//                                self.gameOptions.set(data: data)
//                            }
//                        }
                        Button("Reset") {
                            console.log("resetting")
                            gameOptions.set(data: GameOptionsData(data: GameOptions()))
                        }
                    }.padding(.top)
                }
                
            }
            .formStyle(.columns)
            .toggleStyle(.switch)
            //        .controlSize(/*@START_MENU_TOKEN@*/.mini/*@END_MENU_TOKEN@*/)
        }
        .padding()
        .onAppear() {
            if let data: GameOptionsData = readUsrDefData(key: gameOptKey) {
                self.gameOptions.set(data: data)
            }
            if(!game!.isNative) {
                loadResolutionFromBottle()
            }
        }
    }

    private func loadResolutionFromBottle() {
        guard !appGlobals.selectedBottle.isEmpty,
              let bottleURL = URL(string: appGlobals.selectedBottle) else { return }
        let manager = BottleResolutionManager(bottleURL: bottleURL)
        do {
            let state = try manager.loadCurrentState()
            gameOptions.virtualDesktopEnabled = state.isVirtualDesktopEnabled
            gameOptions.virtualDesktopResolution = state.resolution
        } catch {
            console.error("Failed to load resolution state: \(String(reflecting: error))")
        }
    }

}

#Preview {
    @State @Previewable var game: Game? = .mock
    @StateObject @Previewable var gameOptions: GameOptions = GameOptions(cxGraphicsBackend: "dxmt")
    @StateObject @Previewable var appGlobals: AppGlobals = AppGlobals()

    GameOptionsView(game: $game).environmentObject(gameOptions).environmentObject(appGlobals)
}
