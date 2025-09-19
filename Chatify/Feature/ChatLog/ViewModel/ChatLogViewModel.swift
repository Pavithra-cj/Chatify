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
import FirebaseStorage

class ChatLogViewModel: ObservableObject {
    @Published var chatText = ""
    @Published var errorMessage = ""
    
    @Published var chatMessages = [ChatMessage]()
    
    @Published var count = 0
    @Published var isUploadingImage = false
    @Published var isSendingLocation = false
    @Published var imageUploadProgress: Double? = nil
    
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
            FirebaseConstants.timestamp: FieldValue.serverTimestamp(),
            FirebaseConstants.messageType: "text"
        ]
        
        docRef.setData(messageData) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to save message: \(error.localizedDescription)"
                return
            }
            self?.persistRecentMessage(lastMessageOverride: nil)
            DispatchQueue.main.async {
                self?.chatText = ""
                self?.count += 1
            }
        }
        
        recipientDocRef.setData(messageData) { error in
            if let error = error {
                print("Failed to save recipient message: \(error.localizedDescription)")
            }
        }
    }
    
    private func persistRecentMessage(lastMessageOverride: String?) {
        guard let chatUser = chatUser else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        let lastMessage = lastMessageOverride ?? self.chatText
        
        let finishWrite: (_ currentName: String, _ currentProfile: String?) -> Void = { currentName, currentProfile in
            let userRecentDoc = Firestore.firestore().collection("recent_chats").document(uid).collection("messages").document(toId)
            let recipientRecentDoc = Firestore.firestore().collection("recent_chats").document(toId).collection("messages").document(uid)
            
            let baseData: [String: Any] = [
                FirebaseConstants.timestamp: FieldValue.serverTimestamp(),
                FirebaseConstants.message: lastMessage,
                FirebaseConstants.toId: toId,
                FirebaseConstants.fromId: uid,
                "fromName": currentName,
                "fromProfileImageUrl": currentProfile ?? "",
                "toName": chatUser.name,
                "toProfileImageUrl": chatUser.profileImage ?? "",
                "profileImageUrl": chatUser.profileImage ?? "",
                "displayName": chatUser.name
            ]
            userRecentDoc.setData(baseData) { error in
                if let error = error { self.errorMessage = "Error writing recent chat: \(error.localizedDescription)" }
            }
            recipientRecentDoc.setData(baseData)
        }
        
        if let cache = currentUserCache {
            finishWrite(cache.name, cache.profileImage)
            return
        }
        
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
    
    func sendImage(_ image: UIImage, completion: (() -> Void)? = nil) {
        guard let fromId = Auth.auth().currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        isUploadingImage = true
        imageUploadProgress = 0
        errorMessage = ""
        
        let imageId = UUID().uuidString
        let storagePath = "chat_images/\(fromId)/\(toId)/\(imageId).jpg"
        let ref = Storage.storage().reference().child(storagePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = ref.putData(imageData, metadata: metadata)
        
        uploadTask.observe(.progress) { [weak self] snapshot in
            guard let prog = snapshot.progress else { return }
            DispatchQueue.main.async {
                self?.imageUploadProgress = Double(prog.completedUnitCount) / Double(prog.totalUnitCount)
            }
        }
        
        uploadTask.observe(.failure) { [weak self] snapshot in
            DispatchQueue.main.async {
                self?.errorMessage = "Image upload failed"
                if let err = snapshot.error { self?.errorMessage = "Image upload failed: \(err.localizedDescription)" }
                self?.isUploadingImage = false
                self?.imageUploadProgress = nil
                completion?()
                print("Image upload failed: \(String(describing: snapshot.error))")
            }
        }
        
        uploadTask.observe(.success) { [weak self] _ in
            guard let self = self else { return }
            ref.downloadURL { url, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to get download URL: \(error.localizedDescription)"
                        self.isUploadingImage = false
                        self.imageUploadProgress = nil
                        completion?()
                    }
                    return
                }
                guard let url = url else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Download URL is nil"
                        self.isUploadingImage = false
                        self.imageUploadProgress = nil
                        completion?()
                    }
                    return
                }
                self.saveImageMessage(imageUrl: url.absoluteString, fromId: fromId, toId: toId)
                DispatchQueue.main.async {
                    self.imageUploadProgress = nil
                    completion?()
                }
            }
        }
    }
    
    private func saveImageMessage(imageUrl: String, fromId: String, toId: String) {
        let senderDoc = Firestore.firestore().collection("chats").document(fromId).collection(toId).document()
        let recipientDoc = Firestore.firestore().collection("chats").document(toId).collection(fromId).document()
        
        let data: [String: Any] = [
            FirebaseConstants.fromId: fromId,
            FirebaseConstants.toId: toId,
            FirebaseConstants.message: imageUrl,
            FirebaseConstants.timestamp: FieldValue.serverTimestamp(),
            FirebaseConstants.messageType: "image"
        ]
        
        let group = DispatchGroup()
        var firstError: Error?
        
        group.enter()
        senderDoc.setData(data) { error in
            if let error = error { firstError = error }
            group.leave()
        }
        group.enter()
        recipientDoc.setData(data) { error in
            if let error = error { firstError = error }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isUploadingImage = false
            if let error = firstError {
                self.errorMessage = "Failed to send image message: \(error.localizedDescription)"
            } else {
                self.persistRecentMessage(lastMessageOverride: "📷 Photo")
                self.count += 1
            }
        }
    }
    
    func sendLocation(_ coordinate: CLLocationCoordinate2D, completion: (() -> Void)? = nil) {
        guard !isSendingLocation else { return }
        guard let fromId = Auth.auth().currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        let locationString = "\(coordinate.latitude),\(coordinate.longitude)"
        isSendingLocation = true
        errorMessage = ""
        
        let senderDoc = Firestore.firestore().collection("chats").document(fromId).collection(toId).document()
        let recipientDoc = Firestore.firestore().collection("chats").document(toId).collection(fromId).document()
        let data: [String: Any] = [
            FirebaseConstants.fromId: fromId,
            FirebaseConstants.toId: toId,
            FirebaseConstants.message: locationString,
            FirebaseConstants.timestamp: FieldValue.serverTimestamp(),
            FirebaseConstants.messageType: "location"
        ]
        
        let group = DispatchGroup()
        var firstError: Error?
        
        group.enter()
        senderDoc.setData(data) { error in
            if let error = error { firstError = error }
            group.leave()
        }
        group.enter()
        recipientDoc.setData(data) { error in
            if let error = error { firstError = error }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isSendingLocation = false
            if let error = firstError {
                self.errorMessage = "Failed to send location: \(error.localizedDescription)"
            } else {
                self.persistRecentMessage(lastMessageOverride: "📍 Location")
                self.count += 1
            }
            completion?()
        }
    }
}
