//
//  Options.swift
//  Procyon
//
//  Created by Italo Mandara on 31/01/2026.
//

import SwiftUI

struct OptionsView: View {
    @Binding var showOptions: Bool
    var api: SteamAPI
    var load: () async -> Void
    
    var body: some View {
        Modal(
            showModal: $showOptions,
        ) {
            VStack (alignment: .center){
                Text("Options")
                Spacer()
                Button("Delete cache") {
                    api.deleteCache()
                }.cornerRadius(20)
                Button("Reload") {
                    Task { await load() }
                }
                .cornerRadius(20)
            }
            .frame(width: 300, height: 300)
            .padding()
        }
    }
}
