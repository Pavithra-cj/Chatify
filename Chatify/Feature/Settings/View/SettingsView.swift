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
    @State private var showingLogoutConfirmation = false
    
    // Password change states
    @State private var isChangingPassword = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header with profile card
                        profileHeaderCard
                        
                        // Settings sections
                        VStack(spacing: 20) {
                            // Appearance Section
                            settingsSection(title: "Appearance", icon: "paintbrush") {
                                appearanceSettings
                            }
                            
                            // Security Section
                            settingsSection(title: "Security & Privacy", icon: "lock.shield") {
                                securitySettings
                            }
                            
                            // Notifications Section
                            settingsSection(title: "Notifications", icon: "bell") {
                                notificationSettings
                            }
                            
                            // About Section
                            settingsSection(title: "About", icon: "info.circle") {
                                aboutSettings
                            }
                            
                            // Sign Out Section
                            signOutSection
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Confirm Sign Out", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                handleSignOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertMessage.contains("Error") ? "Error" : "Success"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        
                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 10)
                    )
                }
            }
        }
    }
    
    // MARK: - Profile Header Card
    private var profileHeaderCard: some View {
        NavigationLink(destination: ProfileView(viewModel: viewModel)) {
            HStack(spacing: 16) {
                // Profile Image with gradient border
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    
                    if let base64String = viewModel.profileImage,
                       let imageData = Data(base64Encoded: base64String),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 66, height: 66)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 66, height: 66)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                    }
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.userName.isEmpty ? "Loading..." : viewModel.userName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(viewModel.userEmail.isEmpty ? "Loading..." : viewModel.userEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Verified Account")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Settings Section Builder
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Section Content
            VStack(spacing: 1) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
            )
        }
    }
    
    // MARK: - Appearance Settings
    private var appearanceSettings: some View {
        VStack(spacing: 1) {
            settingsRow(
                icon: "circle.lefthalf.filled",
                title: "Theme",
                subtitle: themeDisplayName
            ) {
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: appTheme) { _, newValue in
                    NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil, userInfo: ["theme": newValue])
                }
            }
        }
    }
    
    private var themeDisplayName: String {
        switch appTheme {
        case "light": return "Light"
        case "dark": return "Dark"
        default: return "System"
        }
    }
    
    // MARK: - Security Settings
    private var securitySettings: some View {
        VStack(spacing: 1) {
            if biometricManager.getBiometricType() != .none {
                settingsToggleRow(
                    icon: biometricManager.getBiometricType() == .faceID ? "faceid" : "touchid",
                    title: "\(biometricManager.getBiometricType().title) Authentication",
                    subtitle: "Use biometric authentication to secure your account",
                    isOn: $useBiometricAuth
                )
                
                Divider()
                    .padding(.leading, 50)
            }
            
            if isChangingPassword {
                passwordChangeView
            } else {
                settingsActionRow(
                    icon: "key",
                    title: "Change Password",
                    subtitle: "Update your account password"
                ) {
                    withAnimation(.easeInOut) {
                        isChangingPassword = true
                    }
                }
            }
        }
    }
    
    private var passwordChangeView: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                SecureField("Current Password", text: $currentPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("New Password", text: $newPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm New Password", text: $confirmNewPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    withAnimation(.easeInOut) {
                        resetPasswordFields()
                    }
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red, lineWidth: 1)
                )
                
                Button("Update") {
                    updatePassword()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(currentPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty ? Color.gray : Color.blue)
                )
                .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty)
            }
        }
        .padding()
    }
    
    // MARK: - Notification Settings
    private var notificationSettings: some View {
        VStack(spacing: 1) {
            settingsToggleRow(
                icon: "message.badge",
                title: "Message Notifications",
                subtitle: "Receive notifications for new messages",
                isOn: .constant(true)
            )
            
            Divider()
                .padding(.leading, 50)
            
            settingsToggleRow(
                icon: "person.badge.plus",
                title: "Friend Requests",
                subtitle: "Get notified when someone sends a friend request",
                isOn: .constant(true)
            )
        }
    }
    
    // MARK: - About Settings
    private var aboutSettings: some View {
        VStack(spacing: 1) {
            settingsActionRow(
                icon: "doc.text",
                title: "Terms of Service",
                subtitle: "Read our terms and conditions"
            ) {
                // Handle terms action
            }
            
            Divider()
                .padding(.leading, 50)
            
            settingsActionRow(
                icon: "hand.raised",
                title: "Privacy Policy",
                subtitle: "Learn about how we protect your data"
            ) {
                // Handle privacy policy action
            }
            
            Divider()
                .padding(.leading, 50)
            
            settingsRow(
                icon: "info.circle",
                title: "Version",
                subtitle: "1.0.0"
            ) {
                EmptyView()
            }
        }
    }
    
    // MARK: - Sign Out Section
    private var signOutSection: some View {
        Button(action: {
            showingLogoutConfirmation = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.square")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Sign out of your account")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Views
    private func settingsRow<Content: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder action: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            action()
        }
        .padding(16)
    }
    
    private func settingsActionRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            settingsRow(icon: icon, title: title, subtitle: subtitle) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func settingsToggleRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        settingsRow(icon: icon, title: title, subtitle: subtitle) {
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
    }
    
    // MARK: - Helper Functions
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
                withAnimation(.easeInOut) {
                    resetPasswordFields()
                }
            }
        }
    }
    
    private func handleSignOut() {
        Task {
            do {
                try Auth.auth().signOut()
                await MainActor.run {
                    isUserLoggedIn = false
                    UserDefaults.standard.removeObject(forKey: "uid")
                    UserDefaults.standard.removeObject(forKey: "email")
                    NotificationCenter.default.post(name: NSNotification.Name("UserDidSignOut"), object: nil)
                }
            } catch {
                await MainActor.run {
                    print("Failed to sign out:", error)
                    alertMessage = "Error: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
