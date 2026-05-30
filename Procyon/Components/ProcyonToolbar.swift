//
//  ProcyonToolbar.swift
//  Procyon
//
//  Created by Italo Mandara on 07/04/2026.
//

import SwiftUI

struct ProcyonToolbar: View {
    @EnvironmentObject var appGlobals: AppGlobals
    @EnvironmentObject var libraryPageGlobals: LibraryPageGlobals
    @Binding var showAddCustomGameView: Bool
    
    let iconSize:CGFloat = 20
    var body: some View {
        HStack(alignment: .center) {
            Button {
                showAddCustomGameView = true
            } label: {
                Image(systemName: "rectangle.badge.plus").resizable().scaledToFit().frame(width: iconSize, height: iconSize)
            }
            if !appGlobals.cxAppPath.isEmpty {
                Divider()
                Button {
                    let cxPath = appGlobals.cxAppPath
                    if !cxPath.isEmpty {
                        let url = URL(fileURLWithPath: cxPath)
                        let configuration = NSWorkspace.OpenConfiguration()
                        configuration.environment = [
                            "CX_GRAPHICS_BACKEND": CXGraphicsBackend.d3dmetal.rawValue,
                            "MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS": "0"
                        ]
                        NSWorkspace.shared.open(url, configuration: configuration)
                    }
                } label: {
                    Image("crossover-fill").resizable().scaledToFit().frame(width: iconSize, height: iconSize)
                }
            }
            if appGlobals.selectedBottle != "" {
                Divider()
                Button {
                    openSteam(cxAppPath: appGlobals.cxAppPath, selectedBottle: appGlobals.selectedBottle, steamWinePath: appGlobals.steamWinePath)
                } label: {
                    Image("steam-fill").resizable().scaledToFit().frame(width: iconSize, height: iconSize)
                }
                Divider()
                Button {
                    if let selectedBottleURL = URL(string: appGlobals.selectedBottle) {
                        showFolder(url: selectedBottleURL)
                    }
                } label: {
                    Image(systemName: "waterbottle").resizable().scaledToFit().frame(width: iconSize, height: iconSize)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 15)
        .frame(height: 35)
        .background(.procyonAccent.mix(with: .black, by: 0.6).opacity(0.9))
        .clipShape(.capsule)
    }
}
