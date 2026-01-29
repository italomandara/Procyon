//
//  ContentView.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import SwiftUI

let sample = [
    "730",
    "44350",
    "214490",
    "252950",
    "292030",
    "323460",
    "337000",
    "359320",
    "374320",
    "397540",
    "601150",
    "750920",
    "814380",
    "851850",
    "955050",
    "979690",
    "1222680",
    "1222730",
    "1233570",
    "1237970",
    "1259420",
    "1282690",
    "1328670",
    "1364780",
    "1372280",
    "1384160",
    "1458040",
    "1490890",
    "1501750",
    "4003800",
    "8870",
    "237630",
    "257030",
    "310950",
    "424840",
    "485510",
    "502500",
    "544750",
    "594330",
    "678960",
    "963220",
    "1057090",
    "1151640",
    "1175190",
    "1342260",
    "1489410",
    "1649240",
    "1693980",
    "2149010",
    "3564740",
    "3564860",
    "3870690"
]

struct ContentView: View {
    @State private var items: [SteamGame] = []
    @State private var isLoading = false
    @State private var showSheet = false
    @State private var errorMessage: String?
    @State private var filter: String = ""
    
    private let api = SteamAPI()
    var body: some View {
        VStack(alignment: .center){
            if isLoading {
                ProgressView("Loading…").frame(width: 1024, height: 600)
            } else if let errorMessage {
                Text("Error: \(errorMessage)")
                    .lineLimit(1)
                    .foregroundStyle(.red)
                    .frame(width: 1024, height: 600)
            } else {
                ZStack(alignment: .bottom)  {
                    GamesView(items: items.filter { item in
                        filter.isEmpty ||
                        item.name.lowercased().contains(filter.lowercased())
                    })
                    Toolbar(filter: $filter, showOptions: $showSheet).padding(.bottom)
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            ZStack(alignment: .topTrailing) {
                VStack (alignment: .center){
                    Text("Options")
                    Spacer()
                    Button("Delete cache") {
                        api.deleteCache()
                    }.disabled(!api.hasCache).cornerRadius(20)
                    Button("Reload") {
                        Task { await load() }
                    }.cornerRadius(20)
                }
                .frame(width: 300, height: 300)
                .padding()
                Button {
                    showSheet = false
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .padding(20)
                .cornerRadius(20)
            }
        }
        .task { await load() }
        .background(
            LinearGradient(
                    colors: [
                        Color(red: 0.60, green: 0.0, blue: 0.0),
                        Color(red: 0.35, green: 0.0, blue: 0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
        )
        .frame(width: 1024, height: 600)
        .fixedSize()
        .transition(.opacity)
    }
    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await api.fetchGamesInfo(appIDs: sample)
        } catch {
            errorMessage = error.localizedDescription
            print(error)
        }
    }
}

#Preview {
    ContentView()
}

