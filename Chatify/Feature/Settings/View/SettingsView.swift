//
//  SettingsView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isUserLoggedIn") var isUserLoggedIn: Bool = false
    @AppStorage("useBiometricAuth") private var useBiometricAuth = false
    @StateObject private var biometricManager = BiometricAuthManager()
    @State private var showingSignOutError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section(header: Text("Security")) {
                if biometricManager.getBiometricType() != .none {
                    Toggle(isOn: $useBiometricAuth) {
                        HStack {
                            Image(systemName: biometricManager.getBiometricType() == .faceID ? "faceid" : "touchid")
                                .foregroundColor(.blue)
                            Text("\(biometricManager.getBiometricType().title) Authentication")
                        }
                    }
                }
            }
            
            Section {
                Button(action: handleSignOut) {
                    HStack {
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Sign Out Error", isPresented: $showingSignOutError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSignOut() {
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Clear user defaults and state
            isUserLoggedIn = false
            UserDefaults.standard.removeObject(forKey: "uid")
            UserDefaults.standard.removeObject(forKey: "email")
            
            // Clear any cached data if needed
            // Reset the app to initial state
            NotificationCenter.default.post(name: NSNotification.Name("UserDidSignOut"), object: nil)
        } catch {
            print("Failed to sign out:", error)
            errorMessage = error.localizedDescription
            showingSignOutError = true
        }
    }
}

#Preview {
    SettingsView()
}
