//
//  CloseModalButton.swift
//  Procyon
//
//  Created by Italo Mandara on 07/02/2026.
//

import SwiftUI

struct CloseModalButton: View {
    @Binding var show: Bool
    
    var body: some View {
        Button {
            show = false
        } label: {
            Image(systemName: "xmark").foregroundStyle(.black)
        }
        .background(.white.opacity(0.5))
        .clipShape(Circle())
        .padding(.vertical)
    }
}

#Preview {
    @State @Previewable var show = true
    CloseModalButton(show: $show)
}
