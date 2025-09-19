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
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isUserLoggedIn") var isUserLoggedIn: Bool = false
    @AppStorage("useBiometricAuth") private var useBiometricAuth = false
    @AppStorage("appTheme") private var appTheme: String = "system"
    @StateObject private var biometricManager = BiometricAuthManager()
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Password change states
    @State private var isChangingPassword = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    
    var body: some View {
        List {
            Section(header: Text("Profile")) {
                NavigationLink(destination: ProfileView(viewModel: viewModel)) {
                    HStack(spacing: 12) {
                        // Profile Image
                        if let base64String = viewModel.profileImage,
                           let imageData = Data(base64Encoded: base64String),
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                .shadow(radius: 2)
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .foregroundColor(.gray)
                        }
                        
                        // User Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.userName)
                                .font(.headline)
                            HStack(spacing: 4) {
                                Text(viewModel.userEmail)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .onChange(of: appTheme) { _, newValue in
                    NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil, userInfo: ["theme": newValue])
                }
            }
            
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
                
                if isChangingPassword {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmNewPassword)
                    
                    Button("Update Password") {
                        updatePassword()
                    }
                    .foregroundColor(.blue)
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty)
                    
                    Button("Cancel") {
                        resetPasswordFields()
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Change Password") {
                        isChangingPassword = true
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
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertMessage.contains("Error") ? "Error" : "Success"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
    }
    
    private func resetPasswordFields() {
        isChangingPassword = false
        currentPassword = ""
        newPassword = ""
        confirmNewPassword = ""
    }
    
    private func updatePassword() {
        guard newPassword == confirmNewPassword else {
            alertMessage = "Error: New passwords don't match"
            showingAlert = true
            return
        }
        
        guard newPassword.count >= 6 else {
            alertMessage = "Error: New password must be at least 6 characters long"
            showingAlert = true
            return
        }
        
        viewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword) { success, message in
            alertMessage = success ? message : "Error: \(message)"
            showingAlert = true
            
            if success {
                resetPasswordFields()
            }
        }
    }
    
    private func handleSignOut() {
        do {
            try Auth.auth().signOut()
            isUserLoggedIn = false
            UserDefaults.standard.removeObject(forKey: "uid")
            UserDefaults.standard.removeObject(forKey: "email")
            NotificationCenter.default.post(name: NSNotification.Name("UserDidSignOut"), object: nil)
        } catch {
            print("Failed to sign out:", error)
            alertMessage = "Error: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
