//
//  Modal.swift
//  Procyon
//
//  Created by Italo Mandara on 01/02/2026.
//

import SwiftUI

struct Modal<Content: View>: View {
    @Binding var showModal: Bool
    let content: Content
    
    init(showModal: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._showModal = showModal
        self.content = content()
    }
    
    var body: some View {
        ZStack (alignment: .topTrailing){
            ScrollView {
                content
            }
            HStack {
                Button {
                    showModal = false
                } label: {
                    Image(systemName: "xmark").foregroundStyle(.black)
                }
                .background(.white.opacity(0.5))
                .clipShape(Circle())
            }.padding()
        }
    }
}
