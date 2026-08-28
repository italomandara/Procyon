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
    @State var isLoading = false
    
    var preferredMaxFrameRate: String {
        $gameOptions.dxmtPreferredMaxFrameRate.wrappedValue < 20.0 ? "Disabled" : "\($gameOptions.dxmtPreferredMaxFrameRate.wrappedValue)"
    }
    
    var d3dMaxFPS: String {
        $gameOptions.d3dMaxFPS.wrappedValue < 20.0 ? "Disabled" : "\($gameOptions.d3dMaxFPS.wrappedValue)"
    }
    
    var body: some View {
        let id = game!.steamAppID != 0 ? String(describing: game!.steamAppID) : String(describing: game!.id)
        let gameOptKey = namespacedKey("GameOptions", id)
        VStack (alignment: .leading, spacing: 5){
            Text("id:\(id)").font(Font.footnote).foregroundStyle(.procyonBrightGray)
            Form {
                VStack(alignment: .leading, spacing: 20) {
                    Section("Generic options") {
                        HStack(alignment: .top, spacing: 20) {
                            VStack(alignment: .trailing){
                                if !game!.isNative {
                                    DropDown(options: cxGraphicsBackend, label: "Graphics Backend", value: $gameOptions.cxGraphicsBackend)
                                }
                                Divider()
                                TextField("Game arguments", text: $gameOptions.gameArguments)
                                TextField("Env variables", text: $gameOptions.envVariables)
                                if !game!.isNative {
                                    Divider()
                                    Text("32Bits options")
                                    Toggle("Use X87 Patch", isOn: $gameOptions.x87PatchEnabled)
                                    Toggle("Use DX9", isOn: $gameOptions.dx9PatchEnabled).onChange(of: gameOptions.dx9PatchEnabled) { oldValue, newValue in
                                        if(newValue == true) {
                                            gameOptions.cxGraphicsBackend = "wine"
                                        }
                                    }  // WINEDLLOVERRIDES=d3d9=n,b;d3d8=n,b has been removed
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Toggle("Metal HUD", isOn: $gameOptions.mtlHudEnabled)
                                Toggle("Advertise AVX", isOn: $gameOptions.advertiseAVX)
                                if !game!.isNative {
                                    Toggle("MSync", isOn: $gameOptions.wineMSync)
                                    Toggle("Enable SDL", isOn: $gameOptions.enableSDL)
                                    Toggle("Disable Hidraw", isOn: $gameOptions.disableHidraw)
                                    Divider()
                                    Text("Vulkan options")
                                    Toggle("Enable UE4 Hack", isOn: $gameOptions.ue4Hack)
                                    Toggle("MTL arg. buffers", isOn: $gameOptions.mvkArgBuff)
                                    DropDown(options: cxVulkanBackend, label: "VK lib", value: $gameOptions.vulkanLib)
                                    .pickerStyle(.menu)
                                }
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
                                    in: 19...400,
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
                    if(gameOptions.cxGraphicsBackend == "d3dmetal4") {
                        Divider()
                        Section("D3DMetal Options") {
                            Toggle("Metal 4 Backend", isOn: $gameOptions.d3dMtl4Enabled)
                                .help(localizedString(forKey: "metal4Backend"))
                                .disabled(OSVersion < 27)
                                .opacity(OSVersion < 27 ? 0.5 : 1.0)
                            VStack{
                                Text(localizedString(forKey: "preferredMaxFrameRate", value: d3dMaxFPS))
                                Slider(
                                    value: $gameOptions.d3dMaxFPS,
                                    in: 19...400,
                                    step: 1.0
                                )
                                .help(localizedString(forKey: "preferredMaxFrameRateHelp"))
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
                        Spacer()
                        ProminentButton("Auto configure", systemImage: "wand.and.sparkles", isLoading: isLoading) {
                            Task {
                                isLoading = true
                                do {
                                    try await autoconfig()
                                } catch {
                                    // display error on the UI
                                    isLoading = false
                                }
                                isLoading = false
                            }
                        }
                    }.padding(.top)
                }
                
            }
            .controlSize(.small)
            .formStyle(.columns)
            .toggleStyle(.switch)
        }
        .padding()
        .onAppear() {
            if let data: GameOptionsData = readUsrDefData(key: gameOptKey) {
                self.gameOptions.set(data: data)
            }
            if !cxGraphicsBackend.contains(where: { $0.id == self.gameOptions.cxGraphicsBackend }) {
                self.gameOptions.cxGraphicsBackend = "d3dmetal4"
            }
        }
    }
    
    @MainActor
    private func autoconfig() async throws {
        if let id = game?.steamAppID {
            if let autoconfigData = try await api.fetchAutoConfig(steamID: String(id)) {
                gameOptions.importAutoConfig(data: autoconfigData)
            }
        }
    }
}

#Preview {
    @State @Previewable var game: Game? = .mock
    @StateObject @Previewable var gameOptions: GameOptions = GameOptions(cxGraphicsBackend: "dxmt")
    
    GameOptionsView(game: $game).environmentObject(gameOptions)

}
