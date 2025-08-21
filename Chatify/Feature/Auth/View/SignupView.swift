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
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var isLoading: Bool = false
    @State private var statusMessage = ""
    
    @State private var shouldShowImagePicker: Bool = false
    @State var image: UIImage?
    
    var body: some View {
        NavigationView{
            ScrollView{
                
                VStack(spacing: 12){
                    
                    Button{
                        shouldShowImagePicker.toggle()
                    } label: {
                        VStack{
                            if let image = self.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 128, height: 128)
                                    .cornerRadius(64)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 64))
                                    .padding()
                                    .foregroundStyle(.gray)
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 64)
                            .stroke(Color.black, lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    Group{
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                        
                        TextField("Name", text: $name)
                            .autocapitalization(.words)
                        
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1))
                    
                    Spacer()
                    
                    Button{
                        handleSignIn()
                    } label: {
                        HStack{
                            Spacer()
                            Text("Signup")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil){
            ImagePicker(image: $image)
        }
    }
    
    private func handleSignIn() {
        
    }
    
}

#Preview {
    SignupView()
}
