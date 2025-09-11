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

class ChatLogViewModel: ObservableObject {
    @Published var chatText = ""
    @Published var errorMessage = ""
    
    @Published var chatMessages = [ChatMessage]()
    
    @Published var count = 0
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    private func fetchMessages() {
        guard let fromId = Auth.auth().currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        Firestore
            .firestore()
            .collection("chats")
            .document(fromId)
            .collection(toId)
            .order(by: "timeStamp")
            .addSnapshotListener { querySnapshot,error in
                if let error = error {
                    print("Error listening for changes: \(error.localizedDescription)")
                    self.errorMessage = "Faield to fetch messages: \(error.localizedDescription)"
                    return
                }
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        let data = change.document.data()
                        
                        self.chatMessages
                            .append(
                                .init(
                                    documentId: change.document.documentID,
                                    data: data
                                )
                            )
                    }
                })
                DispatchQueue.main.async{
                    self.count += 1
                }
            }
    }
    
    func handleSendMessage() {
        print(chatText)
        
        guard let fromId = Auth.auth().currentUser?.uid else { return }
        
        guard let toId = chatUser?.uid else { return }
        
        let document = Firestore.firestore().collection("chats").document(fromId).collection(toId).document()
        
        let recipientMessageDocument = Firestore.firestore().collection("chats").document(toId).collection(fromId).document()
        
//        let messageData = [
//            FirebaseConstants.fromId: fromId,
//            FirebaseConstants.toId: toId,
//            FirebaseConstants.message: self.chatText,
//            FirebaseConstants.timestamp: Timestamp()
//        ] as [String : Any]
        
        let messageData: [String: Any] = [
            FirebaseConstants.fromId: fromId,
            FirebaseConstants.toId: toId,
            FirebaseConstants.message: self.chatText,
            FirebaseConstants.timestamp: FieldValue.serverTimestamp()
        ]
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message: \(error.localizedDescription)"
                return
            }
            
            print("Successfully saved message")
            
            self.persistRecentMessage()
            
            self.chatText = ""
            self.count += 1
        }
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message: \(error.localizedDescription)"
                return
            }
            
            print("Recipeient successfully saved message")
        }
    }
    
    private func persistRecentMessage() {
        guard let chatUser = chatUser else { return }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        guard let toId = self.chatUser?.uid else { return }
        
        let document = Firestore.firestore().collection("recent_chats").document(uid).collection("messages").document(toId)
        
        let recipientMessageDocument = Firestore.firestore().collection("recent_chats").document(toId).collection("messages").document(uid)
        
        let data = [
            "timestamp": Timestamp(),
            FirebaseConstants.message: self.chatText,
            FirebaseConstants.toId: toId,
            FirebaseConstants.fromId: uid,
            "profileImageUrl": chatUser.profileImage ?? "",
            "displayName": chatUser.name
        ] as [String : Any]
        
        document.setData(data) { error in
            if let error = error {
                print("Error writing document: \(error)")
                self.errorMessage = "Error writing document: \(error)"
                return
            }
            
            print("Successfull data added to recent chats")
        }
        
        recipientMessageDocument.setData(data) { error in
            if let error = error {
                self.errorMessage = "Failed to save message: \(error.localizedDescription)"
                return
            }
            
            print("Recipeient successfully saved a recent message")
        }
    }
}
