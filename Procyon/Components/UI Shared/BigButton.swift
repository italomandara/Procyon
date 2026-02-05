//
//  BigButton.swift
//  Procyon
//
//  Created by Italo Mandara on 05/02/2026.
//

import SwiftUI

struct BigButton: View {
    var text: String = ""
    let action: () -> Void
    
    var body: some View {
        Button { action() } label: {
            Text(text)
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 10)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .padding(.top, -12)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }
}

#Preview {
    BigButton(text: "Let'sa go!!", action: {})
}
