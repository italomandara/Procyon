//
//  AccentTag.swift
//  Procyon
//
//  Created by Italo Mandara on 05/02/2026.
//

import SwiftUI

struct AccentTag: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.top, 2)
            .padding(.bottom, 4)
            .background(Color.accent)
            .clipShape(Capsule())
    }
}

#Preview {
   VStack {
        AccentTag("I'm a tag")
   }.padding(20)
}
