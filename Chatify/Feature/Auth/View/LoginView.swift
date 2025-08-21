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
    @State private var statusMessage = ""
    @State private var showPassword = false
    @State private var logoAppeared = false
    
    var body: some View {
        NavigationView{
            ZStack{
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30){
                        
                        VStack(spacing: 10) {
                            Image("AppLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
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
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear{
            logoAppeared = true
        }
    }
    
    private func handleLogin(){
        
    }
    
}

#Preview {
    LoginView(alreadyLoggedIn: {
        
    })
}
