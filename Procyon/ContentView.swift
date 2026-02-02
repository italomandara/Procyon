//
//  ContentView.swift
//  Procyon
//
//  Created by Italo Mandara on 29/01/2026.
//

import SwiftUI
let windowWidth: CGFloat = 1024
let windowHeight: CGFloat = 750

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
    @State private var showOptions = false
    @State private var showDetailView = false
    @State private var errorMessage: String?
    @State private var filter: String = ""
    @State private var progress: Double = 0
    @State private var progressPollTask: Task<Void, Never>? = nil
    @State private var selectedGame: SteamGame? = nil
    
    private var api = SteamAPI()
    
    var body: some View {
        VStack(alignment: .center) {
            if (isLoading) {
                ZStack{
                    Image(.procyon).resizable()
                        .scaledToFill().blendMode(.multiply).opacity(0.1)
                    VStack(alignment: .center) {
                        Image(.procyon).resizable()
                            .scaledToFit()
                            .frame(width: 100)
                        Text("Building your library…")
                            .foregroundStyle(.white)
                            .padding(.top)
                        ProgressView(value: progress, total: 100)
                            .progressViewStyle(.linear)
                            .frame(width: 200, alignment: .center)
                    }
                }.frame(width: windowWidth, height: windowHeight)
            } else if let errorMessage {
                Text("Error: \(errorMessage)")
                    .lineLimit(1)
                    .foregroundStyle(.red)
                    .frame(width: windowWidth, height: windowHeight)
            } else {
                ZStack(alignment: .bottom)  {
                    GamesList(items: items.filter { item in
                        filter.isEmpty ||
                        item.name.lowercased().contains(filter.lowercased())
                    }, showDetailView: $showDetailView, selectedGame: $selectedGame)
                    Toolbar(filter: $filter, showOptions: $showOptions).padding(.bottom)
                }
            }
        }
        .sheet(isPresented: $showOptions) {
            OptionsView(showOptions: $showOptions, api: api, load: load)
        }
        .sheet(isPresented: $showDetailView) {
            Modal(showModal: $showDetailView) {
                GameDetailView(game: $selectedGame)
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
        .frame(width: windowWidth, height: windowHeight)
        .fixedSize()
        .transition(.opacity)
        .onDisappear {
            progressPollTask?.cancel()
            progressPollTask = nil
        }
    }
    @MainActor
    private func load() async {
        isLoading = true
        progress = 0
        progressPollTask?.cancel()
        progressPollTask = Task { @MainActor in
            while !Task.isCancelled {
                self.progress = api.progress
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        defer {
            isLoading = false
            progressPollTask?.cancel()
            progressPollTask = nil
        }
        do {
            items = try await api.fetchGamesInfo(appIDs: sample)
            progress = 100
        } catch {
            errorMessage = error.localizedDescription
            print(error)
        }
    }
}

#Preview {
    ContentView()
}

