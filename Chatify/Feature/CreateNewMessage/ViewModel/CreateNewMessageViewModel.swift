//
//  CreateNewMessageViewModel.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-09.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class CreateNewMessageViewModel: ObservableObject{
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    
    init() {
        fetchAllUsers()
    }
    
    private func fetchAllUsers() {
        Firestore.firestore().collection("user").getDocuments { documentSnapshot, error in
            if let error = error {
                self.errorMessage = "Error fetching users: \(error)"
                print("Error fetching users: \(error)")
                return
            }
            
            documentSnapshot?.documents.forEach({snapshot in
                let data = snapshot.data()
                let user = ChatUser(data: data)
                
                if user.uid != Auth.auth().currentUser?.uid {
                    self.users.append(.init(data: data))
                }
            })
            
            self.errorMessage = "Fetch users successfully"
        }
    }
}
