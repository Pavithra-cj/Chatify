//
//  AppCoordinator.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-15.
//

import SwiftUI
import FirebaseAuth

class AppCoordinator: ObservableObject {
    static let shared = AppCoordinator()
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserDidSignOut"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSignOut()
        }
    }
    
    private func handleSignOut() {
        // Reset any view states
        // Clear any caches
        UserDefaults.standard.synchronize()
        
        // Post notification for views to reset their state
        NotificationCenter.default.post(name: NSNotification.Name("ResetAppState"), object: nil)
    }
}
