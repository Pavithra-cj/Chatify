//
//  SignupView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-08-20.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct SignupView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var isLoading: Bool = false
    @State private var alertMessage = ""
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    
    @State private var shouldShowImagePicker: Bool = false
    @State private var image: UIImage?
    
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var logoAppeared = false
    
    var body: some View {
        NavigationStack{
            ZStack{
                // Background matching LoginView
                ZStack{
                    Image("Background")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                    
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                }
                
                ScrollView {
                    VStack(spacing: 20){
                        
                        VStack{
                            
                            Text("Chatify")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 10)
                        
                        VStack(spacing: 20) {
                            // Header
                            Spacer()
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Sign Up")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Create your account to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Profile Image Picker
                            Button{
                                shouldShowImagePicker.toggle()
                            } label: {
                                VStack{
                                    if let image = self.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                            .frame(width: 100, height: 100)
                                            .background(Color.gray.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                )
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .background(
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 30, height: 30)
                                        )
                                        .offset(x: 35, y: 35)
                                )
                            }
                            
                            // Form Fields
                            VStack(spacing: 15) {
                                TextField("Username", text: $username)
                                    .textInputAutocapitalization(.none)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1))
                                
                                TextField("Full Name", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1))
                                
                                TextField("Email", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.none)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1))
                                
                                // Password field with show/hide toggle
                                HStack{
                                    Group{
                                        if showPassword {
                                            TextField("Password", text: $password)
                                        } else {
                                            SecureField("Password", text: $password)
                                        }
                                    }
                                    
                                    Button(action: { showPassword.toggle()}) {
                                        Image(systemName: showPassword ? "eye" : "eye.slash")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1))
                                
                                // Confirm Password field with show/hide toggle
                                HStack{
                                    Group{
                                        if showConfirmPassword {
                                            TextField("Confirm Password", text: $confirmPassword)
                                        } else {
                                            SecureField("Confirm Password", text: $confirmPassword)
                                        }
                                    }
                                    
                                    Button(action: { showConfirmPassword.toggle()}) {
                                        Image(systemName: showConfirmPassword ? "eye" : "eye.slash")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1))
                            }
                            
                            // Sign Up Button
                            Button {
                                handleSignIn()
                            } label: {
                                HStack{
                                    Spacer()
                                    
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                        
                                        Text("Creating Account...")
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .semibold
                                                )
                                            )
                                    } else {
                                        Text("Sign Up")
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .semibold
                                                )
                                            )
                                    }
                                    
                                    Spacer()
                                }
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            .disabled(
                                email.isEmpty || password.isEmpty ||
                                confirmPassword.isEmpty || name.isEmpty ||
                                username.isEmpty || isLoading
                            )
                            .opacity(
                                email.isEmpty || password.isEmpty ||
                                confirmPassword.isEmpty || name.isEmpty ||
                                username.isEmpty || isLoading ? 0.6 : 1.0
                            )
                            
                            // Back to Login
                            HStack{
                                Text("Already have an account?")
                                    .foregroundColor(.secondary)
                                
                                Button("Sign In"){
                                    dismiss()
                                }
                                .foregroundColor(.blue)
                            }
                            .font(.subheadline)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(20)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { logoAppeared = true }
            
            .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
                ImagePicker(image: $image)
            }
            
            .alert("Sign Up Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            
            .alert("Account Created!", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your account has been created successfully. Please sign in to continue.")
            }
        }
    }
    
    private func handleSignIn() {
        
    }
    
}

#Preview {
    SignupView()
}
