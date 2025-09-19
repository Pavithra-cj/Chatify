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
    
    private let db = Firestore.firestore()
    
    func onCodeScanned(_ code: String) {
        let components = code.split(separator: "_")
        guard components.count >= 1 else { return }
        
        let friendId = String(components[0])
        Task {
            do {
                try await sendFriendRequest(toUserId: friendId)
                alertMessage = "Friend request sent successfully!"
                showAlert = true
                isScanning = false
            } catch {
                alertMessage = "Failed to send friend request: \(error.localizedDescription)"
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
    
    private func sendFriendRequest(toUserId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
        }
        
        // Check if friend request already exists
        let requests = try await db.collection("friend_requests")
            .whereField("fromId", isEqualTo: currentUserId)
            .whereField("toId", isEqualTo: toUserId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        if !requests.documents.isEmpty {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Friend request already sent"])
        }
        
        // Create new friend request
        let friendRequest = [
            "fromId": currentUserId,
            "toId": toUserId,
            "timestamp": Timestamp(),
            "status": "pending"
        ] as [String: Any]
        
        try await db.collection("friend_requests").addDocument(data: friendRequest)
    }
}
