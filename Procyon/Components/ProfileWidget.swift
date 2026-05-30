//
//  ProfileWidget.swift
//  Procyon
//
//  Created by Italo Mandara on 03/03/2026.
//

import SwiftUI
import Kingfisher

struct ProfileWidget: View {
    @EnvironmentObject var appGlobals: AppGlobals
    @State private var isLoading: Bool = true
    @State private var profileData: UserInfo? = nil
    @State private var showProfile: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if isLoading {
                ProgressView().scaleEffect(0.5)
            } else if let p = profileData {
                Button {
                    showProfile = true
                } label: {
                    HStack {
                        KFImage(URL(string: p.avatar))
                            .placeholder {
                                ProgressView()
                            }
                            .resizable()
                            .scaledToFit()
                            .mask(Circle())
                            .padding(5)
                            .frame(width: 40)
                        Text(p.personaName).lineLimit(1)
                    }.frame(maxWidth: 150, alignment: .init(horizontal: .leading, vertical: .center))
                }
                .buttonStyle(.plain)
            } else {
                if let bottlePath = URL(string: appGlobals.selectedBottle) {
                    if let fallbackProfileData = getSteamUserDataFallback(usingBottlePath: bottlePath, steamWinePath: appGlobals.steamWinePath) {
                        HStack {
                            KFImage(URL(string: fallbackProfileData.avatar))
                                .resizable()
                                .scaledToFit()
                                .mask(Circle())
                                .padding(5)
                                .frame(width: 40)
                            Text(fallbackProfileData.personaName).lineLimit(1)
                        }.frame(maxWidth: 150, alignment: .init(horizontal: .leading, vertical: .center))
                    } else {
                        Image(systemName: "person.crop.circle").resizable().scaledToFit().frame(width: 18, height: 18).padding(8)
                    }
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            Modal("Steam profile", showModal: $showProfile) {
                VStack() {
                    if isLoading {
                        VStack {
                            ProgressView("Loading profile…")
                        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else if let p = profileData {
                        let lastLogOff = p.lastLogOff == nil ? "empty" : Date(timeIntervalSince1970: Double(p.lastLogOff!)).formatted()
                        let timeCreated = Date(timeIntervalSince1970: Double(p.timeCreated)).formatted()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack {
                                    KFImage(URL(string: p.avatarFull))
                                        .placeholder {
                                            ProgressView()
                                        }
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(width: 82, height: 82)
                                .cornerRadius(20)
                                .padding(.trailing, 10)
                                VStack (alignment: .leading){
                                    HStack (alignment: .bottom){
                                        Text(p.personaName).font(.largeTitle)
                                        if (p.locCountryCode != nil){
                                            Flag(countryCode: p.locCountryCode!).font(.largeTitle)
                                        }
                                    }
                                    HStack {
                                        Tag(p.communityVisibilityState == 3 ? "Public" : "Private")
                                        Tag(mapPersonaState(p.personaState))
                                    }
                                }
                            }.padding(.bottom)
                            if (p.profileState == 1){
                                Text("Community profile configured")
                                Text("A \"Steam Community profile configured\" means you have completed the initial setup of your profile, enabling you to use social features like adding friends, posting in hubs, and trading. It requires setting up an avatar, username, and often, spending at least $5.00 USD to unlock features from \"limited account\" status.").font(.footnote)
                            } else {
                                Text("Community profile needs to be configured")
                                Text("This means you haven't completed the initial setup of your profile, at the moment you can't use social features like adding friends, posting in hubs, and trading. To configure it, set up an avatar, username, and often, spending at least $5.00 USD will unlock your status.").font(.footnote)
                            }
                            
                            Text("Steam ID: \n\(p.steamID)")
                            Text("Profile URL: \n\(p.profileURL)")
                            //                    Text("avatarHash: \(p.avatarHash)")
                            //                    Text("primaryClanID: \(p.primaryClanID)")
                            Text("Account created on: \n\(timeCreated)")
                            Text("Last Time you logged off: \n\(lastLogOff)")
                            //                    Text("personaStateFlags: \(p.personaStateFlags)")
                            //                    Text("locStateCode: \(p.locStateCode ?? "-")")
                            Spacer()
                            VStack(alignment: .leading) {
                                ProminentButton("Reload Profile Data", systemImage: "arrow.clockwise") {
                                    isLoading = true
                                    api.deleteProfileDataCache()
                                    Task(priority: .background){
                                        await load()
                                    }
                                }
                            }.padding(.top)
                        }
                        .padding(.vertical)
                        .cornerRadius(20)
                    } else {
                        Text("No profile data")
                    }
                }.frame(width: 500, height: 450, alignment: .center)
            }
        }
        .onAppear(perform: {
            Task(priority: .background) {
                await load()
            }
        })
    }
    
    @MainActor
    private func load() async {
        defer {
            isLoading = false
        }
        do {
            if(!appGlobals.userID.isEmpty){
                profileData = try await api.fetchProfileDetails(userID: appGlobals.userID)
            } else {
                appGlobals.userID = getSteamUserID(usingBottlePath: URL(string: appGlobals.selectedBottle)!, steamWinePath: appGlobals.steamWinePath) ?? ""
                if(!appGlobals.userID.isEmpty){
                    profileData = try await api.fetchProfileDetails(userID: appGlobals.userID)
                } else {
                    console.error("Couldn't find the userID")
                }
            }
        } catch {
            console.error(String(reflecting: error))
        }
    }
}



#Preview {
    ProfileWidget()
}
