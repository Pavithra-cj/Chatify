//
//  HomeView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @State private var selectedTab = 0
    @State private var showQRCode = false
    @State private var showScanner = false
    @State private var selectedChatUser: ChatUser? = nil
    @State private var navigateToChatLog = false
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                MainMessageView(
                    showQRCode: $showQRCode,
                    showScanner: $showScanner,
                    onChatSelected: { user in
                        selectedChatUser = user
                        navigateToChatLog = true
                    }
                )
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chats")
                }
                .tag(0)
                
                StatusView()
                    .tabItem {
                        Image(systemName: "circle.dashed")
                        Text("Status")
                    }
                    .tag(1)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(2)
            }
            .navigationDestination(isPresented: $navigateToChatLog) {
                if let user = selectedChatUser {
                    ChatLogView(chatUser: user)
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
