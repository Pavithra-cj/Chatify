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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                MainMessageView(showQRCode: $showQRCode, showScanner: $showScanner)
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Chats")
            }
            .tag(0)
            
            NavigationView {
                StatusView()
            }
            .tabItem {
                Image(systemName: "circle.dashed")
                Text("Status")
            }
            .tag(1)
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(2)
        }
    }
}

#Preview {
    HomeView()
}
