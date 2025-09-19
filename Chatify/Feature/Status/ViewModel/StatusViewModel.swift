//
//  StatusViewModel.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-19.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class StatusViewModel: ObservableObject {
    @Published var currentUserStatuses: [Status] = []
    @Published var friendsStatusGroups: [UserStatusGroup] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showImagePicker = false
    @Published var selectedImage: UIImage?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private var currentUserStatusListener: ListenerRegistration?
    private var friendStatusListeners: [ListenerRegistration] = []
    private var friendStatusesByUser: [String: [Status]] = [:]
    
    init() {
        fetchStatuses()
    }
    
    deinit {
        removeAllListeners()
    }
    
    private func removeAllListeners() {
        currentUserStatusListener?.remove()
        friendStatusListeners.forEach { $0.remove() }
        friendStatusListeners.removeAll()
    }
    
    func fetchStatuses() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        removeAllListeners()
        fetchCurrentUserStatuses(userId: currentUserId)
        fetchFriendsStatuses(currentUserId: currentUserId)
    }
    
    private func fetchCurrentUserStatuses(userId: String) {
        currentUserStatusListener = db.collection("statuses")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                guard let documents = snapshot?.documents else { return }
                let statuses = documents.compactMap { doc in
                    try? doc.data(as: Status.self)
                }.filter { !$0.isExpired }
                DispatchQueue.main.async {
                    self?.currentUserStatuses = statuses
                }
            }
    }
    
    private func fetchFriendsStatuses(currentUserId: String) {
        // Fetch friend IDs from the user document (collection name aligned with FriendsViewModel)
        db.collection("user").document(currentUserId).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
                return
            }
            guard let data = snapshot?.data() else {
                self?.friendsStatusGroups = []
                self?.isLoading = false
                return
            }
            let friendIds = data["friends"] as? [String] ?? []
            self?.attachFriendStatusListeners(friendIds: friendIds)
        }
    }
    
    private func attachFriendStatusListeners(friendIds: [String]) {
        // Clear existing friend listeners
        friendStatusListeners.forEach { $0.remove() }
        friendStatusListeners.removeAll()
        friendStatusesByUser.removeAll()
        friendsStatusGroups = []
        
        guard !friendIds.isEmpty else {
            isLoading = false
            return
        }
        
        let chunkSize = 10
        let chunks: [[String]] = stride(from: 0, to: friendIds.count, by: chunkSize).map { start in
            Array(friendIds[start..<min(start + chunkSize, friendIds.count)])
        }
        
        for chunk in chunks {
            let listener = db.collection("statuses")
                .whereField("userId", in: chunk) // Removed order(by:) to avoid composite index need; we sort client-side
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        self.isLoading = false
                        return
                    }
                    // Map statuses for this chunk
                    let statuses = documents.compactMap { try? $0.data(as: Status.self) }.filter { !$0.isExpired }
                    let grouped = Dictionary(grouping: statuses) { $0.userId }
                    // Update chunk users
                    for userId in chunk {
                        if let userStatuses = grouped[userId] {
                            self.friendStatusesByUser[userId] = userStatuses
                        } else {
                            // No statuses
                            self.friendStatusesByUser.removeValue(forKey: userId)
                        }
                    }
                    self.rebuildFriendGroups()
                    self.isLoading = false
                }
            friendStatusListeners.append(listener)
        }
    }
    
    private func rebuildFriendGroups() {
        let groups = friendStatusesByUser.map { (userId, statuses) -> UserStatusGroup in
            let sorted = statuses.sorted { $0.timestamp > $1.timestamp }
            let first = sorted.first!
            return UserStatusGroup(
                id: userId,
                userId: userId,
                username: first.username,
                userProfileImageUrl: first.userProfileImageUrl,
                statuses: sorted
            )
        }.sorted { ($0.latestStatus?.timestamp ?? .distantPast) > ($1.latestStatus?.timestamp ?? .distantPast) }
        DispatchQueue.main.async {
            self.friendsStatusGroups = groups
        }
    }
    
    func uploadStatus(image: UIImage) {
        guard let currentUser = Auth.auth().currentUser,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        isLoading = true
        let statusId = UUID().uuidString
        // Updated path to include userId folder for security rules
        let storageRef = storage.reference().child("status_images").child("\(currentUser.uid)/\(statusId).jpg")
        storageRef.putData(imageData, metadata: nil) { [weak self] _, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                    return
                }
                guard let downloadURL = url else {
                    self?.isLoading = false
                    return
                }
                self?.saveStatusToFirestore(
                    statusId: statusId,
                    imageUrl: downloadURL.absoluteString,
                    userId: currentUser.uid
                )
            }
        }
    }
    
    private func saveStatusToFirestore(statusId: String, imageUrl: String, userId: String) {
        db.collection("user").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
                return
            }
            let userData = document?.data() ?? [:]
            let username = userData["username"] as? String ?? userData["name"] as? String ?? ""
            let profileImageUrl = (userData["profileImage"] as? String) ?? (userData["profileImageUrl"] as? String)
            let status = Status(
                id: statusId,
                userId: userId,
                username: username,
                userProfileImageUrl: profileImageUrl,
                imageUrl: imageUrl,
                timestamp: Date(),
                viewerIds: []
            )
            do {
                try self?.db.collection("statuses").document(statusId).setData(from: status)
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.selectedImage = nil
                }
            } catch {
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
            }
        }
    }
    
    func markStatusAsViewed(statusId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("statuses").document(statusId).updateData([
            "viewerIds": FieldValue.arrayUnion([currentUserId])
        ])
    }
    
    func deleteExpiredStatuses() {
        let expiredDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
        
        db.collection("statuses")
            .whereField("timestamp", isLessThan: expiredDate)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for document in documents {
                    document.reference.delete()
                }
            }
    }
}
