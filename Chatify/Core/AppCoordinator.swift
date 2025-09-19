//
//  AppCoordinator.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-15.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

class AppCoordinator: ObservableObject {
    static let shared = AppCoordinator()
    
    // Deep link targets from notifications
    @Published var deepLinkTargetChatUserId: String? = nil
    @Published var showFriendRequestsFromNotification: Bool = false
    
    private var authListener: AuthStateDidChangeListenerHandle?
    private var lastUserId: String?
    
    init() {
        setupNotifications()
        setupAuthListener()
    }
    
    func refreshAuthState() {
        // listener set in init
    }
    
    private func setupAuthListener() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let user = user {
                lastUserId = user.uid
                Messaging.messaging().token { token, _ in
                    guard let token else { return }
                    Firestore.firestore().collection("user").document(user.uid).setData(["fcmToken": token], merge: true)
                }
            } else {
                if let old = lastUserId {
                    Firestore.firestore().collection("user").document(old).setData(["fcmToken": FieldValue.delete()]) { _ in }
                }
                lastUserId = nil
            }
        }
    }
    
    // Handle remote notification payloads routed from AppDelegate
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        switch type {
        case "message":
            if let chatUserId = userInfo["chatUserId"] as? String {
                deepLinkTargetChatUserId = chatUserId
                NotificationCenter.default.post(name: .openChatFromNotification, object: chatUserId)
            }
        case "friend_request":
            showFriendRequestsFromNotification = true
            NotificationCenter.default.post(name: .showFriendRequestsFromNotification, object: nil)
        default:
            break
        }
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
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name("ResetAppState"), object: nil)
    }
}

extension Notification.Name {
    static let openChatFromNotification = Notification.Name("OpenChatFromNotification")
    static let showFriendRequestsFromNotification = Notification.Name("ShowFriendRequestsFromNotification")
}
