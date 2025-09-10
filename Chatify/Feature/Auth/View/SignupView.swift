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
    
    @StateObject private var viewModel: SignupViewModel
    
    init(alreadyLoggedIn: @escaping () -> ()) {
        _viewModel = StateObject(wrappedValue: SignupViewModel(alreadyLoggedIn: alreadyLoggedIn))
    }
    
    var body: some View {
        NavigationStack{
            ZStack{
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
                                viewModel.shouldShowImagePicker.toggle()
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
                                TextField("Username", text: $viewModel.username)
                                    .textInputAutocapitalization(.never)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1))
                                
                                TextField("Full Name", text: $viewModel.name)
                                    .textInputAutocapitalization(.words)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1))
                                
                                TextField("Email", text: $viewModel.email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1))
                                
                                // Password field with show/hide toggle
                                HStack{
                                    Group{
                                        if viewModel.showPassword {
                                            TextField("Password", text: $viewModel.password)
                                        } else {
                                            SecureField("Password", text: $viewModel.password)
                                        }
                                    }
                                    
                                    Button(action: { viewModel.showPassword.toggle()}) {
                                        Image(systemName: viewModel.showPassword ? "eye" : "eye.slash")
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
                                        if viewModel.showConfirmPassword {
                                            TextField("Confirm Password", text: $viewModel.confirmPassword)
                                        } else {
                                            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                        }
                                    }
                                    
                                    Button(action: { viewModel.showConfirmPassword.toggle()}) {
                                        Image(systemName: viewModel.showConfirmPassword ? "eye" : "eye.slash")
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
                                viewModel.handleSignUp()
                            } label: {
                                HStack{
                                    Spacer()
                                    
                                    if viewModel.isLoading {
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
                                viewModel.email.isEmpty || viewModel.password.isEmpty ||
                                viewModel.confirmPassword.isEmpty || viewModel.name.isEmpty ||
                                viewModel.username.isEmpty || viewModel.isLoading
                            )
                            .opacity(
                                viewModel.email.isEmpty || viewModel.password.isEmpty ||
                                viewModel.confirmPassword.isEmpty || viewModel.name.isEmpty ||
                                viewModel.username.isEmpty || viewModel.isLoading ? 0.6 : 1.0
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
            .onAppear { viewModel.logoAppeared = true }
            
            .fullScreenCover(isPresented: $viewModel.shouldShowImagePicker, onDismiss: nil) {
                ImagePicker(image: $viewModel.image)
            }
            
            .alert("Sign Up Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.alertMessage)
            }
            
            .alert("Account Created!", isPresented: $viewModel.showSuccessAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your account has been created successfully. Please sign in to continue.")
            }
        }
    }
    
}

#Preview {
    SignupView(alreadyLoggedIn: {
        
    })
}
