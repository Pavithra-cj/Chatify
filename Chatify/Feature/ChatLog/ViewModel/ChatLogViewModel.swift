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
    
    init(chatUser: ChatUser?) { self.chatUser = chatUser; fetchMessages() }
    deinit { messagesListener?.remove() }
    
    private func fetchMessages() {
        chatMessages.removeAll(); messagesListener?.remove()
        guard let fromId = Auth.auth().currentUser?.uid, let toId = chatUser?.uid else { return }
        let ref = Firestore.firestore().collection("chats").document(fromId).collection(toId).order(by: FirebaseConstants.timestamp, descending: false)
        messagesListener = ref.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error = error { self.errorMessage = "Failed to fetch messages: \(error.localizedDescription)"; return }
            snapshot?.documentChanges.forEach { change in
                let data = change.document.data()
                switch change.type {
                case .added:
                    let msg = ChatMessage(documentId: change.document.documentID, data: data)
                    if !self.chatMessages.contains(where: { $0.documentId == msg.documentId }) { self.chatMessages.append(msg) }
                case .modified:
                    let updated = ChatMessage(documentId: change.document.documentID, data: data)
                    if let idx = self.chatMessages.firstIndex(where: { $0.documentId == updated.documentId }) { self.chatMessages[idx] = updated }
                case .removed:
                    self.chatMessages.removeAll { $0.documentId == change.document.documentID }
                }
            }
            self.chatMessages.sort { $0.timestamp.dateValue() < $1.timestamp.dateValue() }
            DispatchQueue.main.async { self.count += 1 }
        }
    }
    
    func handleSendMessage() {
        guard let fromId = Auth.auth().currentUser?.uid, let toId = chatUser?.uid else { return }
        let trimmed = chatText.trimmingCharacters(in: .whitespacesAndNewlines); guard !trimmed.isEmpty else { return }
        let plaintext = trimmed
        EncryptionManager.shared.encrypt(plaintext, to: toId) { [weak self] payload in
            guard let self else { return }
            let isEncrypted = payload != nil
            let cipherOrPlain = payload?.ciphertext ?? plaintext
            let base: [String: Any] = [
                FirebaseConstants.fromId: fromId,
                FirebaseConstants.toId: toId,
                FirebaseConstants.message: cipherOrPlain,
                FirebaseConstants.timestamp: FieldValue.serverTimestamp(),
                FirebaseConstants.messageType: "text",
                FirebaseConstants.isEncrypted: isEncrypted,
                FirebaseConstants.senderPublicKey: payload?.senderPublicKey ?? "",
                FirebaseConstants.recipientPublicKey: payload?.recipientPublicKey ?? ""
            ]
            let senderDoc = Firestore.firestore().collection("chats").document(fromId).collection(toId).document()
            let recipientDoc = Firestore.firestore().collection("chats").document(toId).collection(fromId).document(senderDoc.documentID)
            let group = DispatchGroup(); var firstError: Error?
            group.enter(); senderDoc.setData(base) { e in if let e = e { firstError = e }; group.leave() }
            group.enter(); recipientDoc.setData(base) { e in if let e = e { firstError = e }; group.leave() }
            group.notify(queue: .main) {
                if let err = firstError { self.errorMessage = "Failed to save message: \(err.localizedDescription)"; return }
                self.persistRecentMessage(lastMessageOverride: nil, encryptionPayload: payload)
                self.chatText = ""; self.count += 1
            }
        }
    }
    
    private func persistRecentMessage(lastMessageOverride: String?, encryptionPayload: EncryptionManager.EncryptionPayload?) {
        guard let chatUser, let uid = Auth.auth().currentUser?.uid, let toId = chatUser.uid as String? else { return }
        let isEncrypted = encryptionPayload != nil
        let storedMessage: String
        if let override = lastMessageOverride { storedMessage = override } else if let payload = encryptionPayload { storedMessage = payload.ciphertext } else { storedMessage = chatText }
        let finish: (_ currentName: String, _ currentProfile: String?) -> Void = { currentName, currentProfile in
            let userDoc = Firestore.firestore().collection("recent_chats").document(uid).collection("messages").document(toId)
            let recipDoc = Firestore.firestore().collection("recent_chats").document(toId).collection("messages").document(uid)
            var base: [String: Any] = [
                FirebaseConstants.timestamp: FieldValue.serverTimestamp(),
                FirebaseConstants.message: storedMessage,
                FirebaseConstants.toId: toId,
                FirebaseConstants.fromId: uid,
                "fromName": currentName,
                "fromProfileImageUrl": currentProfile ?? "",
                "toName": chatUser.name,
                "toProfileImageUrl": chatUser.profileImage ?? "",
                "profileImageUrl": chatUser.profileImage ?? "",
                "displayName": chatUser.name,
                FirebaseConstants.isEncrypted: isEncrypted
            ]
            if let p = encryptionPayload { base[FirebaseConstants.senderPublicKey] = p.senderPublicKey; base[FirebaseConstants.recipientPublicKey] = p.recipientPublicKey }
            userDoc.setData(base) { if let e = $0 { self.errorMessage = "Error writing recent chat: \(e.localizedDescription)" } }
            recipDoc.setData(base)
        }
        if let cache = currentUserCache { finish(cache.name, cache.profileImage); return }
        Firestore.firestore().collection("user").document(uid).getDocument { snap, _ in
            let data = snap?.data() ?? [:]
            let name = data["name"] as? String ?? data["username"] as? String ?? ""
            let profile = data["profileImage"] as? String
            self.currentUserCache = (name, profile)
            finish(name, profile)
        }
    }
    
    func sendImage(_ image: UIImage, completion: (() -> Void)? = nil) {
        guard let fromId = Auth.auth().currentUser?.uid, let toId = chatUser?.uid, let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        isUploadingImage = true; imageUploadProgress = 0; errorMessage = ""
        let imageId = UUID().uuidString
        let ref = Storage.storage().reference().child("chat_images/\(fromId)/\(toId)/\(imageId).jpg")
        let metadata = StorageMetadata(); metadata.contentType = "image/jpeg"
        let task = ref.putData(imageData, metadata: metadata)
        task.observe(.progress) { [weak self] snap in guard let prog = snap.progress else { return }; DispatchQueue.main.async { self?.imageUploadProgress = Double(prog.completedUnitCount)/Double(prog.totalUnitCount) } }
        task.observe(.failure) { [weak self] snap in DispatchQueue.main.async { self?.errorMessage = snap.error?.localizedDescription ?? "Image upload failed"; self?.isUploadingImage = false; self?.imageUploadProgress = nil; completion?() } }
        task.observe(.success) { [weak self] _ in
            guard let self else { return }
            ref.downloadURL { url, error in
                if let error = error { DispatchQueue.main.async { self.errorMessage = error.localizedDescription; self.isUploadingImage = false; self.imageUploadProgress = nil; completion?() }; return }
                guard let url else { DispatchQueue.main.async { self.errorMessage = "Download URL nil"; self.isUploadingImage = false; self.imageUploadProgress = nil; completion?() }; return }
                self.encryptAndStoreMedia(url.absoluteString, type: "image", fromId: fromId, toId: toId) { completion?() }
            }
        }
    }
    
    private func encryptAndStoreMedia(_ value: String, type: String, fromId: String, toId: String, completion: @escaping () -> Void) {
        EncryptionManager.shared.encrypt(value, to: toId) { [weak self] payload in
            guard let self else { return }
            let isEncrypted = payload != nil
            let cipherOrPlain = payload?.ciphertext ?? value
            let senderDoc = Firestore.firestore().collection("chats").document(fromId).collection(toId).document()
            let recipientDoc = Firestore.firestore().collection("chats").document(toId).collection(fromId).document(senderDoc.documentID)
            var data: [String: Any] = [
                FirebaseConstants.fromId: fromId,
                FirebaseConstants.toId: toId,
                FirebaseConstants.message: cipherOrPlain,
                FirebaseConstants.timestamp: FieldValue.serverTimestamp(),
                FirebaseConstants.messageType: type,
                FirebaseConstants.isEncrypted: isEncrypted
            ]
            if let p = payload { data[FirebaseConstants.senderPublicKey] = p.senderPublicKey; data[FirebaseConstants.recipientPublicKey] = p.recipientPublicKey }
            let group = DispatchGroup(); var firstError: Error?
            group.enter(); senderDoc.setData(data) { if let e = $0 { firstError = e }; group.leave() }
            group.enter(); recipientDoc.setData(data) { if let e = $0 { firstError = e }; group.leave() }
            group.notify(queue: .main) {
                self.isUploadingImage = false; self.imageUploadProgress = nil
                if let error = firstError { self.errorMessage = "Failed to send \(type) message: \(error.localizedDescription)" } else {
                    let placeholder = type == "image" ? "\u{1F4F7} Photo" : (type == "location" ? "\u{1F4CD} Location" : type.capitalized)
                    EncryptionManager.shared.encrypt(placeholder, to: toId) { phPayload in
                        self.persistRecentMessage(lastMessageOverride: nil, encryptionPayload: phPayload ?? payload)
                        self.count += 1
                    }
                }
                completion()
            }
        }
    }
    
    func sendLocation(_ coordinate: CLLocationCoordinate2D, completion: (() -> Void)? = nil) {
        guard !isSendingLocation, let fromId = Auth.auth().currentUser?.uid, let toId = chatUser?.uid else { return }
        isSendingLocation = true; errorMessage = ""
        let locationString = "\(coordinate.latitude),\(coordinate.longitude)"
        encryptAndStoreMedia(locationString, type: "location", fromId: fromId, toId: toId) { [weak self] in self?.isSendingLocation = false; completion?() }
    }
}
