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
    private var listener: ListenerRegistration?
    
    init() {
        
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = Auth.auth().currentUser?.uid == nil
        }
        
        fetchCurrentUser()
        
        fetchRecentMessages()
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
    
}
