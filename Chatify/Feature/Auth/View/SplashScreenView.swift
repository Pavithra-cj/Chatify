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
    @State private var logoRotation: Double = 0
    @State private var logoOpacity: Double = 0.0
    
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        Group{
            if isActive {
                if gotoLogin {
                    LoginView(alreadyLoggedIn: {
                        isActive = true
                        gotoLogin = false
                    })
                } else {
                    HomeView()
                }
            } else {
                splashContent
            }
        }
        .onAppear{
            checkAuthenticationStatus()
            runSpalshAnimation()
            setupNotifications()
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
                        .rotationEffect(.degrees(logoRotation))
                        .offset(y: logoOffset)
                        .opacity(logoOpacity)
                    
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
        logoScale = 0.1
        logoOpacity = 0.0
        textOpacity = 0.0
        logoRotation = -180
        
        // Animate logo appearance with rotation
        withAnimation(.easeOut(duration: 0.6)) {
            logoScale = 1.2
            logoOpacity = 1.0
            logoRotation = 0
        }
        
        // Scale bounce effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                logoScale = 1.0
            }
        }
        
        // Fade in text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.4)) {
                textOpacity = 1.0
            }
        }
        
        // Final exit animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.7)) {
                logoOffset = -120
                logoScale = 0.7
                logoRotation = 360
                textOpacity = 0.0
                logoOpacity = 0.0
            }
        }
        
        // Transition to main content
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isActive = true
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserDidSignOut"),
            object: nil,
            queue: .main
        ) { _ in
            gotoLogin = true
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
