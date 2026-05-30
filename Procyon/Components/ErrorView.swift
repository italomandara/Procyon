//
//  ErrorView.swift
//  Procyon
//
//  Created by Coderdifference on 30/5/2026.
//

import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let okTitle: String
    @Binding var isPresented: Bool

    init(title: String, message: String, okTitle: String = "OK", isPresented: Binding<Bool>) {
        self.title = title
        self.message = message
        self.okTitle = okTitle
        self._isPresented = isPresented
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .transition(.opacity)

            // Card
            VStack(spacing: 16) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: { isPresented = false }) {
                    Text(okTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: 20)
            .frame(maxWidth: 360)
            .padding()
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.snappy, value: isPresented)
        .opacity(isPresented ? 1 : 0)
    }
}

#Preview {
    StatefulPreviewWrapper(true) { isPresented in
        ZStack {
            Color.gray.opacity(0.2).ignoresSafeArea()
            if isPresented.wrappedValue {
                ErrorView(title: "Something went wrong", message: "We couldn't complete your request. Please try again.", isPresented: isPresented)
            }
        }
    }
}

// Helper to preview bindings without depending on app code
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View { content($value) }
}
