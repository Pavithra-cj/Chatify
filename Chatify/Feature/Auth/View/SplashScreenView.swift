//
//  SplashScreenView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-08-20.
//

import SwiftUI
import FirebaseAuth
import CoreData

struct SplashScreenView: View {
    
    @State private var isActive = false
    @State private var gotoLogin = false
    
    @State private var logoOffset: CGFloat = 0
    @State private var logoScale: CGFloat = 1.0
    @State private var textOpacity: Double = 1.0
    @State private var animateToTop = false
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        
        if isActive {
            if gotoLogin{
                LoginView(alreadyLoggedIn: {
                    
                })
            } else {
                MainMessageView()
            }
        } else {
            ZStack{
                ZStack{
                    Image("Background")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                    
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                }
                
                VStack{
                    Spacer()
                    
                    VStack(spacing: 20){
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 120, height: 120)
                            )
                            .scaleEffect(logoScale)
                            .offset(y: logoOffset)
                        
                        Text("Chatify")
                            .font(.system(size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(textOpacity)
                    }
                    
                    Spacer()
                    
                    Text("ITZcorpio © 2025")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.bottom, 50)
                        .opacity(textOpacity)
                    
                }
            }
            .onAppear{
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                    animateToLogin()
                }
            }
        }
    }
    
    private func animateToLogin(){
        withAnimation(.easeInOut(duration: 1.0)){
            logoOffset = -UIScreen.main.bounds.height * 0.4
            logoScale = 0.6
            textOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
            
        }
    }
    
    private func checkAuthenticationStatus(){
        if Auth.auth().currentUser != nil {
            gotoLogin = false
            isActive = true
        } else {
            gotoLogin = true
            isActive = false
        }
    }
    
}

#Preview {
    SplashScreenView()
}
