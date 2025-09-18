//
//  MainMessageViewModel.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-08.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class MainMessagesViewModel: ObservableObject{
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    
    @Published var isUserCurrentlyLoggedOut: Bool = false
    
    @Published var recentMessages = [RecentMessage]()
    @Published var friendRequests = [FriendRequest]()
    private var listener: ListenerRegistration?
    private var friendRequestListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init() {
        
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = Auth.auth().currentUser?.uid == nil
        }
        
        fetchCurrentUser()
        
        fetchRecentMessages()
        
        listenForFriendRequests()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func fetchRecentMessages(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Remove old listener if any
        listener?.remove()
        
        listener = Firestore
            .firestore()
            .collection("recent_chats")
            .document(uid)
            .collection("messages")
            .order(by: FirebaseConstants.timestamp, descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Failed to fetch recent messages: \(error.localizedDescription)")
                    return
                }
                
                snapshot?.documentChanges.forEach { change in
                    let data = change.document.data()
                    let docId = change.document.documentID
                    let recent = RecentMessage(documentId: docId, data: data)
                    
                    if let index = self.recentMessages.firstIndex(where: { $0.documentId == docId }) {
                        // Update existing
                        self.recentMessages[index] = recent
                    } else {
                        // Insert new
                        self.recentMessages.insert(recent, at: 0)
                    }
                }
                
                // Ensure sorted by timestamp
                self.recentMessages.sort { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            }
    }
    
    func fetchCurrentUser(){
        guard let uid = Auth.auth().currentUser?.uid
        else {
            self.errorMessage = "Could not find firebase UID"
            return
        }
        
        Firestore.firestore().collection("user").document(uid).getDocument{
            snapshot,
            error in
            if let error = error {
                self.errorMessage = "Failed to fetch current user: \(error)"
                print("Failed to fetch current user: \(error)")
                return
            }
            
            guard let data = snapshot?.data()
            else {
                self.errorMessage = "No data found"
                return
            }
            
            //            self.errorMessage = "Data: \(data.description)"
            
            self.chatUser = .init(data: data)
        }
    }
    
    func handleSignOut(){
        do {
            try Auth.auth().signOut()
            isUserCurrentlyLoggedOut.toggle()
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    func listenForFriendRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        friendRequestListener = db.collection("friend_requests")
            .whereField("toId", isEqualTo: uid)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self?.friendRequests = documents.compactMap { document -> FriendRequest? in
                    var request = try? document.data(as: FriendRequest.self)
                    request?.id = document.documentID
                    return request
                }
            }
    }
    
    func acceptFriendRequest(_ request: FriendRequest) {
        let batch = db.batch()
        
        // Update request status
        let requestRef = db.collection("friend_requests").document(request.id)
        batch.updateData(["status": "accepted"], forDocument: requestRef)
        
        // Add to current user's friends
        let currentUserRef = db.collection("user").document(request.toId)
        batch.updateData([
            "friends": FieldValue.arrayUnion([request.fromId])
        ], forDocument: currentUserRef)
        
        // Add to sender's friends
        let senderRef = db.collection("user").document(request.fromId)
        batch.updateData([
            "friends": FieldValue.arrayUnion([request.toId])
        ], forDocument: senderRef)
        
        batch.commit { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func rejectFriendRequest(_ request: FriendRequest) {
        let requestRef = db.collection("friend_requests").document(request.id)
        requestRef.updateData([
            "status": "rejected"
        ]) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
}
