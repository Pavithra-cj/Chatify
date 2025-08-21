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
    
    var body: some View {
        Group{
            if isActive {
                if gotoLogin {
                    LoginView(alreadyLoggedIn: {
                        isActive = true
                        gotoLogin = false
                    })
                } else {
                    MainMessageView()
                }
            } else {
                splashContent
            }
        }
        .onAppear{
            checkAuthenticationStatus()
            runSpalshAnimation()
        }
    }
    
    private var splashContent: some View {
        ZStack{
            Image("Background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack{
                Spacer()
                
                VStack(spacing: 20) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 120, height: 120)
                        )
                        .scaleEffect(logoScale)
                        .offset(y: logoOffset)
                    
                    Text("Chatify")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(textOpacity)
                }
                
                Spacer()
                
                Text("ITZcorpio © 2025")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 40)
                    .opacity(textOpacity)
            }
        }
    }
    
    private func runSpalshAnimation(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 1.0)){
                logoOffset = -120
                logoScale = 0.7
                textOpacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isActive = true
        }
    }
    
    private func checkAuthenticationStatus(){
        if Auth.auth().currentUser != nil {
            gotoLogin = false
        } else {
            gotoLogin = true
        }
    }
    
}

#Preview {
    SplashScreenView()
}
