//
//  CreateNewMessageViewModel.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-09.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class CreateNewMessageViewModel: ObservableObject {
    @Published var users = [Friend]()
    @Published var errorMessage = ""
    
    func fetchFriends() {
        self.users.removeAll()
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("user").document(uid)
            .getDocument { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = "Error fetching friends: \(error.localizedDescription)"
                    return
                }
                
                guard let self = self,
                      let data = snapshot?.data(),
                      let friendIds = data["friends"] as? [String] else { return }
                
                for friendId in friendIds {
                    self.fetchFriendData(friendId: friendId)
                }
            }
    }
    
    private func fetchFriendData(friendId: String) {
        Firestore.firestore().collection("user").document(friendId)
            .getDocument { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = "Error fetching friend data: \(error.localizedDescription)"
                    return
                }
                
                guard let self = self,
                      let data = snapshot?.data() else { return }
                
                let friend = Friend(id: friendId,
                                  userId: friendId,
                                  username: data["username"] as? String ?? "",
                                  email: data["email"] as? String ?? "",
                                  name: data["name"] as? String ?? data["username"] as? String ?? "",
                                  profileImageUrl: data["profileImageUrl"] as? String ?? "")
                
                DispatchQueue.main.async {
                    self.users.append(friend)
                }
            }
    }
}
