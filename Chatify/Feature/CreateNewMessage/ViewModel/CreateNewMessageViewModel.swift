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
                      let data = document.data(),
                      let friendIds = data["friends"] as? [String] else {
                    self.users = []
                    return
                }
                
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
                            profileImageUrl: data["profileImage"] as? String // Changed from profileImageUrl to profileImage
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
            
        } catch {
            self.errorMessage = "Error fetching friends: \(error.localizedDescription)"
        }
    }
    
    func refreshFriends() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                let snapshot = try await Firestore.firestore()
                    .collection("user")
                    .document(uid)
                    .getDocument()
                
                guard let data = snapshot.data(),
                      let friendIds = data["friends"] as? [String] else {
                    self.users = []
                    return
                }
                
                await fetchFriendsData(friendIds: friendIds)
            } catch {
                self.errorMessage = "Error refreshing friends: \(error.localizedDescription)"
            }
        }
    }
}
