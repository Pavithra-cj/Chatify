//
//  SettingsViewModel.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-19.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

class SettingsViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var profileImage: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    @Published var messageNotificationsEnabled: Bool = true
    @Published var friendRequestNotificationsEnabled: Bool = true
    @Published var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isUpdatingNotifications: Bool = false
    
    init() {
        fetchUserData()
        refreshNotificationAuthorizationStatus()
    }
    
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        Firestore.firestore().collection("user").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            guard let data = snapshot?.data() else { return }
            self.userName = data["username"] as? String ?? ""
            self.userEmail = data["email"] as? String ?? ""
            self.profileImage = data["profileImage"] as? String
            if let msgPref = data["messageNotificationsEnabled"] as? Bool { self.messageNotificationsEnabled = msgPref }
            if let frPref = data["friendRequestNotificationsEnabled"] as? Bool { self.friendRequestNotificationsEnabled = frPref }
        }
    }
    
    func updateUserProfile(newUsername: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        Firestore.firestore().collection("user").document(uid).updateData([
            "username": newUsername
        ]) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            self.userName = newUsername
            completion(true)
        }
    }
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(false)
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        isLoading = true
        
        Firestore.firestore().collection("user").document(uid).updateData([
            "profileImage": base64String
        ]) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            self.profileImage = base64String
            completion(true)
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (Bool, String) -> Void) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            completion(false, "User not found")
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                completion(true, "Password updated successfully")
            }
        }
    }
    
    func refreshNotificationAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { self.notificationAuthorizationStatus = settings.authorizationStatus }
        }
    }
    func notificationPreferenceChanged() {
        saveNotificationPreferences(applyRegistrationLogic: true)
    }
    private func saveNotificationPreferences(applyRegistrationLogic: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isUpdatingNotifications = true
        let data: [String: Any] = [
            "messageNotificationsEnabled": messageNotificationsEnabled,
            "friendRequestNotificationsEnabled": friendRequestNotificationsEnabled
        ]
        Firestore.firestore().collection("user").document(uid).setData(data, merge: true) { [weak self] _ in
            guard let self else { return }
            if applyRegistrationLogic { self.applyPushRegistrationLogic() } else { self.isUpdatingNotifications = false }
        }
    }
    private func applyPushRegistrationLogic() {
        #if canImport(UIKit)
        DispatchQueue.main.async {
            if !self.messageNotificationsEnabled && !self.friendRequestNotificationsEnabled {
                // Disable push
                UIApplication.shared.unregisterForRemoteNotifications()
                if let uid = Auth.auth().currentUser?.uid {
                    Firestore.firestore().collection("user").document(uid).setData(["fcmToken": FieldValue.delete()], merge: true)
                }
                self.isUpdatingNotifications = false
            } else {
                // Ensure authorized & registered
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.authorizationStatus == .notDetermined {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                            self.refreshNotificationAuthorizationStatus()
                            if granted {
                                DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
                                self.persistCurrentFCMToken()
                            } else {
                                DispatchQueue.main.async { self.isUpdatingNotifications = false }
                            }
                        }
                    } else if settings.authorizationStatus == .denied {
                        DispatchQueue.main.async { self.isUpdatingNotifications = false }
                    } else {
                        DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
                        self.persistCurrentFCMToken()
                    }
                }
            }
        }
        #else
        self.isUpdatingNotifications = false
        #endif
    }
    private func persistCurrentFCMToken() {
        Messaging.messaging().token { token, _ in
            guard let token, let uid = Auth.auth().currentUser?.uid else { DispatchQueue.main.async { self.isUpdatingNotifications = false }; return }
            Firestore.firestore().collection("user").document(uid).setData(["fcmToken": token], merge: true) { _ in
                DispatchQueue.main.async { self.isUpdatingNotifications = false }
            }
        }
    }
}
