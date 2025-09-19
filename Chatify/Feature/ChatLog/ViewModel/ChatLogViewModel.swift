//
//  ChatLogViewModel.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-09.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import MapKit
import CoreLocation

class ChatLogViewModel: ObservableObject {
    @Published var chatText = ""
    @Published var errorMessage = ""
    
    @Published var chatMessages = [ChatMessage]()
    
    @Published var count = 0
    
    let chatUser: ChatUser?
    
    private var messagesListener: ListenerRegistration?
    private var currentUserCache: (name: String, profileImage: String?)?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    deinit {
        messagesListener?.remove()
    }
    
    private func fetchMessages() {
        // Clear previous messages & remove old listener
        self.chatMessages.removeAll()
        messagesListener?.remove()
        
        guard let fromId = Auth.auth().currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        let ref = Firestore.firestore()
            .collection("chats")
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp, descending: false)
        
        self.messagesListener = ref.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening for changes: \(error.localizedDescription)")
                self.errorMessage = "Failed to fetch messages: \(error.localizedDescription)"
                return
            }
            
            querySnapshot?.documentChanges.forEach { change in
                if change.type == .added {
                    let data = change.document.data()
                    let message = ChatMessage(documentId: change.document.documentID, data: data)
                    
                    // Prevent duplicates
                    if !self.chatMessages.contains(where: { $0.documentId == message.documentId }) {
                        self.chatMessages.append(message)
                    }
                } else if change.type == .modified {
                    // Optionally handle modified messages
                    let data = change.document.data()
                    let updated = ChatMessage(documentId: change.document.documentID, data: data)
                    if let idx = self.chatMessages.firstIndex(where: { $0.documentId == updated.documentId }) {
                        self.chatMessages[idx] = updated
                    }
                } else if change.type == .removed {
                    self.chatMessages.removeAll { $0.documentId == change.document.documentID }
                }
            }
            
            self.chatMessages.sort { $0.timestamp.dateValue() < $1.timestamp.dateValue() }
            
            DispatchQueue.main.async {
                self.count += 1
            }
        }
        
        print("Fetching messages (listener set)")
    }
    
    func handleSendMessage() {
        guard let fromId = Auth.auth().currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        guard !chatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let docRef = Firestore.firestore().collection("chats").document(fromId).collection(toId).document()
        let recipientDocRef = Firestore.firestore().collection("chats").document(toId).collection(fromId).document()
        
        let messageData: [String: Any] = [
            FirebaseConstants.fromId: fromId,
            FirebaseConstants.toId: toId,
            FirebaseConstants.message: self.chatText,
            FirebaseConstants.timestamp: FieldValue.serverTimestamp()
        ]
        
        // Write sender copy
        docRef.setData(messageData) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to save message: \(error.localizedDescription)"
                return
            }
            print("Successfully saved message to sender path")
            self?.persistRecentMessage()
            DispatchQueue.main.async {
                self?.chatText = ""
                self?.count += 1
            }
        }
        
        // Write recipient copy
        recipientDocRef.setData(messageData) { error in
            if let error = error {
                print("Failed to save recipient message: \(error.localizedDescription)")
                return
            }
            print("Recipient successfully saved message")
        }
    }
    
    private func persistRecentMessage() {
        guard let chatUser = chatUser else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        let lastMessage = self.chatText
        
        let finishWrite: (_ currentName: String, _ currentProfile: String?) -> Void = { currentName, currentProfile in
            let userRecentDoc = Firestore.firestore().collection("recent_chats").document(uid).collection("messages").document(toId)
            let recipientRecentDoc = Firestore.firestore().collection("recent_chats").document(toId).collection("messages").document(uid)
            
            let baseData: [String: Any] = [
                FirebaseConstants.timestamp: FieldValue.serverTimestamp(),
                FirebaseConstants.message: lastMessage,
                FirebaseConstants.toId: toId,
                FirebaseConstants.fromId: uid,
                // New schema (both participant metadata)
                "fromName": currentName,
                "fromProfileImageUrl": currentProfile ?? "",
                "toName": chatUser.name,
                "toProfileImageUrl": chatUser.profileImage ?? "",
                // Backward compatibility (old fields the UI might still read)
                "profileImageUrl": chatUser.profileImage ?? "",
                "displayName": chatUser.name
            ]
            
            // Write sender side
            userRecentDoc.setData(baseData) { error in
                if let error = error {
                    print("Error writing recent chat for user: \(error.localizedDescription)")
                    self.errorMessage = "Error writing recent chat: \(error.localizedDescription)"
                    return
                }
                print("Successfully updated recent chat for user (new schema)")
            }
            
            // Write recipient side (same metadata works for both perspectives)
            recipientRecentDoc.setData(baseData) { error in
                if let error = error {
                    print("Error writing recent chat for recipient: \(error.localizedDescription)")
                    return
                }
                print("Recipient successfully updated recent chat (new schema)")
            }
        }
        
        if let cache = currentUserCache {
            finishWrite(cache.name, cache.profileImage)
            return
        }
        
        // Fetch current user metadata once
        Firestore.firestore().collection("user").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch current user for recent message: \(error.localizedDescription)")
                finishWrite("", nil)
                return
            }
            let data = snapshot?.data() ?? [:]
            let currentName = data["name"] as? String ?? data["username"] as? String ?? ""
            let currentProfile = data["profileImage"] as? String
            self.currentUserCache = (currentName, currentProfile)
            finishWrite(currentName, currentProfile)
        }
    }
    
    func sendImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        // Upload image to Firebase Storage and get URL
        // Then send message with image URL and messageType = "image"
    }
    
    func sendLocation(_ coordinate: CLLocationCoordinate2D) {
        let locationString = "\(coordinate.latitude),\(coordinate.longitude)"
        // Send message with location string and messageType = "location"
    }
}
