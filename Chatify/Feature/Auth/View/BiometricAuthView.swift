import SwiftUI

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
                Image(systemName: biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 56))
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Authentication Required")
                    .font(.title2)
                    .bold()
                
                Text("Please authenticate to access Chatify")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if biometricManager.biometricType == .none {
                    Text("Biometric authentication is not available on this device")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if !biometricManager.isAuthenticated && !isAuthenticating {
                    Button(action: authenticate) {
                        Text("Authenticate with \(biometricManager.biometricType.title)")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(biometricManager.biometricType == .none ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(biometricManager.biometricType == .none)
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
            if !biometricManager.isAuthenticated {
                authenticate()
            }
        }
        .onChange(of: biometricManager.isAuthenticated) { newValue in
            isAuthenticated = newValue
            if newValue {
                dismiss()
            }
        }
        .alert("Authentication Failed", isPresented: $showingError) {
            Button("Try Again", action: authenticate)
            Button("Cancel", role: .cancel) {
                isAuthenticated = false
                biometricManager.reset()
                dismiss()
            }
        } message: {
            Text(biometricManager.biometricError?.localizedDescription ?? "Please try again")
        }
    }
    
    private func authenticate() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        
        biometricManager.authenticate { success in
            withAnimation {
                isAuthenticating = false
                if !success {
                    showingError = true
                }
            }
        }
    }
}
