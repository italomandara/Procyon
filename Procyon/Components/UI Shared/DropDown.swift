//
//  DropDown.swift
//  Procyon
//
//  Created by Italo Mandara on 02/07/2026.
//

import SwiftUI

struct DropDown: View {
    var options: DropdownOptions
    var label: String
    @Binding var value: String
    
    var body: some View {
        Picker(label, selection: $value) {
            ForEach(options, id: \.id) { (id, label) in
                Text(label).tag(id)
            }
        }
    }
}

#Preview {
    @Previewable @State var selected = "1"
    DropDown(options: [("1", "Option 1"), ("2", "Option 2")], label: "Dropdown", value: $selected)
}
