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
    
    let alreadyLoggedIn: () -> ()
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var alertMessage = ""
    @State private var showErrorAlert = false
    
    @State private var showPassword = false
    @State private var logoAppeared = false
    
    @State private var showForgotPassword = false
    @State private var showSignUp = false
    
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
                                .scaleEffect(logoAppeared ? 1.0 : 0.6)
                                .animation(
                                    .easeOut(duration: 0.5),
                                    value: logoAppeared
                                )
                            
                            Text("Chatify")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        VStack (spacing: 20) {
                            Spacer()
                            VStack (alignment: .leading, spacing: 1) {
                                Text("Sign In")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Please sign in to continue")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.none)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1))
                            
                            HStack{
                                Group{
                                    if showPassword {
                                        TextField("Password", text: $password)
                                    } else {
                                        SecureField(
                                            "Password",
                                            text: $password
                                        )
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
                            
                            HStack{
                                Spacer()
                                
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            
//                            Spacer()
                            
                            Button {
                                handleLogin()
                            } label: {
                                HStack{
                                    Spacer()
                                    
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                        
                                        Text("Signing In...")
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .semibold
                                                )
                                            )
                                    } else {
                                        Text("Login")
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
                                email.isEmpty || password.isEmpty || isLoading
                            )
                            .opacity(email.isEmpty || password.isEmpty || isLoading ? 0.6 : 1.0)
                            
                            HStack{
                                Text("Don't have an account?")
                                    .foregroundColor(.secondary)
                                
                                Button("Sign Up"){
                                    showSignUp = true
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
//            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { logoAppeared = true }
            
            .navigationDestination(
                isPresented: $showForgotPassword
            ) {
                ForgotPasswordView()
            }
            
            .navigationDestination(
                isPresented: $showSignUp
            ) {
                SignupView()
            }
            
            .alert("Login Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleLogin(){
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in all fields"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    alertMessage = error.localizedDescription
                    showErrorAlert = true
                } else {
                    alreadyLoggedIn()
                }
            }
        }
    }
}

#Preview {
    LoginView(alreadyLoggedIn: {
        
    })
}
