//
//  Tag.swift
//  Procyon
//
//  Created by Italo Mandara on 01/02/2026.
//

import SwiftUI

struct Tag: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .lineLimit(1)
            .foregroundStyle(.procyonDarkGray)
            .padding(.horizontal, 10)
            .padding(.top, 2)
            .padding(.bottom, 4)
            .background(.procyonBrightGray)
            .clipShape(Capsule())
    }
}

#Preview {
   VStack {
        Tag("I'm a tag and I'm proud of it")
   }.padding(20).frame(width: 200)
}
