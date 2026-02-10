//
//  Modal.swift
//  Procyon
//
//  Created by Italo Mandara on 01/02/2026.
//

import SwiftUI

struct Modal<Content: View>: View {
    @Binding var showModal: Bool
    var collapse: Bool? = false
    let content: Content
    
    init(showModal: Binding<Bool>, collapse: Bool? = nil, @ViewBuilder content: () -> Content) {
        self._showModal = showModal
        self.collapse = collapse
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.vertical) {
            content
        }
        .overlay(alignment: .topTrailing) {
            CloseModalButton(show: $showModal)
        }.padding(.horizontal, collapse == true ? 0 : 5)
    }
}
