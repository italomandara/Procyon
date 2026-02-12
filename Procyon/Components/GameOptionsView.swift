//
//  GameOptionsView.swift
//  Procyon
//
//  Created by Italo Mandara on 12/02/2026.
//

import SwiftUI

struct GameOptionsView: View {
    @Binding var game: SteamGame?
    @EnvironmentObject var gameOptions: GameOptions
    
    var preferredMaxFrameRate: String {
        $gameOptions.dxmtPreferredMaxFrameRate.wrappedValue < 20.0 ? "Disabled" : "\($gameOptions.dxmtPreferredMaxFrameRate.wrappedValue)"
    }
    
    var body: some View {
        let gameOptKey = namespacedKey("GameOptions", String(game!.id))
        
        Form {
            VStack(alignment: .leading, spacing: 20) {
                Section("Launch options") {
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 20){
                            Picker("Graphics Backend", selection: $gameOptions.cxGraphicsBackend) {
                                Text("D3DMetal")
                                    .tag("d3dmetal")
                                Text("DXMT")
                                    .tag("dxmt")
                            }
                            .pickerStyle(.menu)
                            TextField("Game arguments", text: $gameOptions.gameArguments)
                            TextField("Env variables", text: $gameOptions.envVariables)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Toggle("MSync", isOn: $gameOptions.wineMSync)
                            Toggle("Metal HUD", isOn: $gameOptions.mtlHudEnabled)
                            Toggle("Advertise AVX", isOn: $gameOptions.advertiseAVX)
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
                HStack {
                    Button("Save settings") {
                        console.log("saving")
                        persistUsrDefData(key: gameOptKey, data: GameOptionsData(data: gameOptions))
                    }.buttonStyle(.borderedProminent)
                    Button("Reset settings") {
                        console.log("resetting")
                        gameOptions.set(data: GameOptionsData(data: GameOptions()))
                    }
                }.padding(.top)
            }
            
        }
        .formStyle(.columns)
        .toggleStyle(.switch)
        //        .controlSize(/*@START_MENU_TOKEN@*/.mini/*@END_MENU_TOKEN@*/)
        .padding()
        .onAppear() {
            if let data: GameOptionsData = readUsrDefData(key: gameOptKey) {
                self.gameOptions.set(data: data)
            }
        }
    }
}

#Preview {
    @State @Previewable var game: SteamGame? = .mock
    @StateObject @Previewable var gameOptions: GameOptions = GameOptions(cxGraphicsBackend: "dxmt")
    
    GameOptionsView(game: $game).environmentObject(gameOptions)

}
