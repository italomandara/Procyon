//
//  Toolbar.swift
//  Procyon
//
//  Created by Italo Mandara on 30/01/2026.
//

import SwiftUI

struct Toolbar: View {
    @Binding var filter: String
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
            }.cornerRadius(20)
            Button("Profile") {
            }.cornerRadius(20)

            TextField("Search Game...", text: $filter)
                .textFieldStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(width: 200)
                .background(.white.opacity(0.2))
                .foregroundStyle(.white)
                .cornerRadius(20)
                .disableAutocorrection(true)
                .focusEffectDisabled()
        }
        .padding(6)
        .background(.black.opacity(0.9))
        .foregroundStyle(.white)
        .cornerRadius(20)
    }
}
