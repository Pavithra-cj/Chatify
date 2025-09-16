//
//  CreateNewMessageViewModel.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-09.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class CreateNewMessageViewModel: ObservableObject {
    @Published var users = [Friend]()
    @Published var errorMessage = ""
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        setupFriendsListener()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    private func setupFriendsListener() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        listenerRegistration = db.collection("user").document(uid)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let document = documentSnapshot,
                      document.exists,
                      let data = document.data() else {
                    self.users = []
                    return
                }
                
                // Get the friends array, if it doesn't exist, use empty array
                let friendIds = data["friends"] as? [String] ?? []
                
                Task {
                    await self.fetchFriendsData(friendIds: friendIds)
                }
            }
    }
    
    private func fetchFriendsData(friendIds: [String]) async {
        do {
            let db = Firestore.firestore()
            var friends: [Friend] = []
            
            // Fetch all friend documents in parallel
            try await withThrowingTaskGroup(of: Friend?.self) { group in
                for friendId in friendIds {
                    group.addTask {
                        let snapshot = try await db.collection("user").document(friendId).getDocument()
                        guard let data = snapshot.data() else { return nil }
                        
                        return Friend(
                            id: friendId,
                            userId: friendId,
                            username: data["username"] as? String ?? "",
                            email: data["email"] as? String ?? "",
                            name: data["name"] as? String ?? "",
                            profileImageUrl: data["profileImageUrl"] as? String
                        )
                    }
                }
                
                // Collect all friend data
                for try await friend in group {
                    if let friend = friend {
                        friends.append(friend)
                    }
                }
            }
            
            // Sort friends by name for consistent display
            self.users = friends.sorted { $0.name < $1.name }
            self.errorMessage = "" // Clear any previous errors
            
        } catch {
            self.errorMessage = "Error fetching friends: \(error.localizedDescription)"
        }
    }
    
    func refreshFriends() {
        setupFriendsListener()
    }
}
