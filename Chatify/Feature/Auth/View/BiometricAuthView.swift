//
//  BiometricAuthView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import SwiftUI
import LocalAuthentication

struct BiometricAuthView: View {
    @StateObject private var biometricManager = BiometricAuthManager()
    @Binding var isAuthenticated: Bool
    @State private var showingError = false
    @State private var isAuthenticating = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: iconName)
                    .font(.system(size: 56))
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Authentication Required")
                    .font(.title2)
                    .bold()
                
                Text(descriptionText)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if !biometricManager.isAuthenticated && !isAuthenticating {
                    Button(action: authenticate) {
                        Text(buttonTitle)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                if isAuthenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
        }
        .onAppear {
            biometricManager.refreshBiometricType()
            if !biometricManager.isAuthenticated {
                authenticate()
            }
        }
        .onChange(of: biometricManager.isAuthenticated) { newValue in
            isAuthenticated = newValue
            if newValue { dismiss() }
        }
        .alert("Authentication Failed", isPresented: $showingError) {
            Button("Try Again", action: authenticate)
            Button("Cancel", role: .cancel) {
                isAuthenticated = false
                biometricManager.reset()
                dismiss()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var iconName: String {
        switch biometricManager.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock.circle"
        }
    }
    
    private var buttonTitle: String {
        "Authenticate with \(biometricManager.biometricType.title)"
    }
    
    private var descriptionText: String {
        switch biometricManager.biometricType {
        case .none:
            return "Use your device passcode to unlock Chatify"
        case .touchID, .faceID:
            return "Please authenticate to access Chatify"
        }
    }
    
    private var errorMessage: String {
        if let err = biometricManager.biometricError as? LAError {
            switch err.code {
            case .biometryLockout: return "Biometrics locked. Use passcode or wait before trying again."
            case .biometryNotEnrolled: return "No biometrics enrolled. Enroll in Settings or use passcode."
            case .biometryNotAvailable: return "Biometric hardware not available. Use passcode."
            default: break
            }
        }
        return biometricManager.biometricError?.localizedDescription ?? "Please try again"
    }
    
    private func authenticate() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        biometricManager.authenticate { success in
            withAnimation {
                isAuthenticating = false
                if !success { showingError = true }
            }
        }
    }
}
