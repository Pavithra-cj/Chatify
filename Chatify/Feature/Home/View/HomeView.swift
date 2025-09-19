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
    @State private var hideTabBar = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    MainMessageView(showQRCode: $showQRCode, showScanner: $showScanner, hideTabBar: $hideTabBar)
                }
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chats")
                }
                .tag(0)
                
                NavigationStack {
                    StatusView()
                }
                .tabItem {
                    Image(systemName: "circle.dashed")
                    Text("Status")
                }
                .tag(1)
                
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
            }
            .opacity(hideTabBar ? 0 : 1)
            
            if hideTabBar {
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {}
            }
        }
    }
}

#Preview {
    HomeView()
}
