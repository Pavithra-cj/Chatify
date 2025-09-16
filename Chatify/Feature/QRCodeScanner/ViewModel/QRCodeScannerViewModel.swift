//
//  QRCodeScannerViewModel.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import Foundation
import SwiftUI
import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

@MainActor
class QRCodeScannerViewModel: ObservableObject {
    @Published var scannedCode: String? = nil
    @Published var isScanning: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    func onCodeScanned(_ code: String) {
        let components = code.split(separator: "_")
        guard components.count >= 1 else { return }
        
        let friendId = String(components[0])
        Task {
            do {
                try await addBidirectionalFriendship(friendId: friendId)
                alertMessage = "Friend added successfully!"
                showAlert = true
                isScanning = false
                NotificationCenter.default.post(name: NSNotification.Name("RefreshFriendsList"), object: nil)
            } catch {
                alertMessage = "Failed to add friend: \(error.localizedDescription)"
                showAlert = true
                isScanning = false
            }
        }
        scannedCode = code
    }
    
    func reset() {
        scannedCode = nil
        isScanning = true
    }
    
    private func addBidirectionalFriendship(friendId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
        }
        
        guard currentUserId != friendId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot add yourself as a friend"])
        }
        
        let db = Firestore.firestore()
        
        // Get both users' data
        let userSnapshot = try await db.collection("user").document(currentUserId).getDocument()
        let friendSnapshot = try await db.collection("user").document(friendId).getDocument()
        
        guard userSnapshot.exists && friendSnapshot.exists,
              let userData = userSnapshot.data(),
              let friendData = friendSnapshot.data() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
        }
        
        // Get existing friend lists or create empty arrays
        var currentUserFriends = (userData["friends"] as? [String]) ?? []
        var friendUserFriends = (friendData["friends"] as? [String]) ?? []
        
        // Add each user to the other's friend list if not already present
        if !currentUserFriends.contains(friendId) {
            currentUserFriends.append(friendId)
        }
        
        if !friendUserFriends.contains(currentUserId) {
            friendUserFriends.append(currentUserId)
        }
        
        // Update both users' documents in a batch
        let batch = db.batch()
        
        let currentUserRef = db.collection("user").document(currentUserId)
        let friendUserRef = db.collection("user").document(friendId)
        
        batch.setData(["friends": currentUserFriends], forDocument: currentUserRef, merge: true)
        batch.setData(["friends": friendUserFriends], forDocument: friendUserRef, merge: true)
        
        try await batch.commit()
    }
}
