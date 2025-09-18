//
//  LoginView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-08-20.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct LoginView: View {
    
    @StateObject private var viewModel: LoginViewModel
    
    init(alreadyLoggedIn: @escaping () -> ()) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(alreadyLoggedIn: alreadyLoggedIn))
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
                    VStack(spacing: 30){
                        
                        VStack(spacing: 10) {
                            Image("AppLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 80, height: 80)
                                        .shadow(
                                            color: .gray.opacity(0.3),
                                            radius: 4, x: 0, y: 2
                                        )
                                )
                                .scaleEffect(viewModel.logoAppeared ? 1.0 : 0.6)
                                .animation(
                                    .easeOut(duration: 0.5),
                                    value: viewModel.logoAppeared
                                )
                            
                            Text("Chatify")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        AuthFormContainer {
                            VStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Sign In")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                        .padding(.top, 10)
                                    
                                    Text("Please sign in to continue")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                AuthTextField(
                                    placeholder: "Email",
                                    text: $viewModel.email,
                                    keyboard: .emailAddress,
                                    autocapitalization: .never
                                )
                                
                                AuthSecureField(
                                    placeholder: "Password",
                                    text: $viewModel.password,
                                    showPassword: $viewModel.showPassword
                                )
                                
                                HStack {
                                    Spacer()
                                    Button("Forgot Password?") {
                                        viewModel.showForgotPassword = true
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                }
                                
                                Button {
                                    viewModel.handleLogin()
                                } label: {
                                    HStack {
                                        Spacer()
                                        if viewModel.isLoading {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.white)
                                            Text("Signing In...")
                                                .foregroundColor(.white)
                                                .padding(.vertical, 10)
                                                .font(.system(size: 14, weight: .semibold))
                                        } else {
                                            Text("Login")
                                                .foregroundColor(.white)
                                                .padding(.vertical, 10)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        Spacer()
                                    }
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                }
                                .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.isLoading)
                                .opacity(viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.isLoading ? 0.6 : 1.0)
                                
                                HStack {
                                    Text("Don't have an account?")
                                        .foregroundColor(.secondary)
                                    Button("Sign Up") {
                                        viewModel.showSignUp = true
                                    }
                                    .foregroundColor(.blue)
                                }
                                .font(.subheadline)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .cornerRadius(20)
                        .padding(20)
                    }
                }
            }
//            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { viewModel.logoAppeared = true }
            
            .navigationDestination(
                isPresented: $viewModel.showForgotPassword
            ) {
                ForgotPasswordView()
            }
            
            .navigationDestination(
                isPresented: $viewModel.showSignUp
            ) {
                SignupView(
                    alreadyLoggedIn: {
                        
                    }
                )
            }
            
            .alert("Login Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
}

#Preview {
    LoginView(alreadyLoggedIn: {
        
    })
}
