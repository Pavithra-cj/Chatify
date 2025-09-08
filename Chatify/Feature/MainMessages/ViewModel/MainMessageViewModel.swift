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
    
    init() {
        
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = Auth.auth().currentUser?.uid == nil
        }
        
        fetchCurrentUser()
        
        fetchRecentMessages()
    }
    
    private func fetchRecentMessages(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore
            .firestore()
            .collection("recent_chats")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener{
                querySnapshot,
                error in
                if let error = error {
                    self.errorMessage = "Failed to listen recent messages: \(error)"
                    print("Failed to listen recent messages: \(error)")
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    
                    if let index = self.recentMessages.firstIndex(where: {rm in
                        return rm.documentId == docId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    
                    self.recentMessages
                        .insert(
                            .init(documentId: docId, data: change.document.data()), at: 0
                        )
                    
                    //                    self.recentMessages
                    //                        .append(
                    //                            .init(
                    //                                documentId: docId,
                    //                                data: change.document.data()
                    //                            )
                    //                        )
                })
                print ("Recent Messages Fetched Successfully")
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
