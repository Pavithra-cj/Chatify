import Foundation
import FirebaseAuth
import FirebaseFirestore

class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var errorMessage: String = ""
    
    private var friendsListener: ListenerRegistration?
    private var requestsListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init() {
        setupListeners()
    }
    
    deinit {
        friendsListener?.remove()
        requestsListener?.remove()
    }
    
    private func setupListeners() {
        listenToFriendRequests()
        fetchFriends()
    }
    
    func listenToFriendRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        requestsListener = db.collection("friend_requests")
            .whereField("toId", isEqualTo: uid)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self?.friendRequests = documents.compactMap { document in
                    let data = document.data()
                    guard let fromId = data["fromId"] as? String,
                          let toId = data["toId"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp,
                          let status = data["status"] as? String else {
                        return nil
                    }
                    
                    return FriendRequest(
                        id: document.documentID,
                        fromId: fromId,
                        toId: toId,
                        timestamp: timestamp.dateValue(),
                        status: FriendRequest.RequestStatus(rawValue: status) ?? .pending
                    )
                }
            }
    }
    
    func fetchFriends() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Clear existing friends before fetching
        DispatchQueue.main.async {
            self.friends = []
        }
        
        // Get the current user's document to access their friends array
        db.collection("user").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            guard let data = snapshot?.data(),
                  let friendIds = data["friends"] as? [String] else { return }
            
            // Fetch each friend's details
            for friendId in friendIds {
                self?.db.collection("user").document(friendId).getDocument { snapshot, error in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    if let data = snapshot?.data() {
                        let friend = Friend(
                            id: friendId,
                            userId: friendId,
                            username: data["username"] as? String ?? "",
                            email: data["email"] as? String ?? "",
                            name: data["name"] as? String ?? "",
                            profileImageUrl: data["profileImage"] as? String
                        )
                        
                        DispatchQueue.main.async {
                            if !(self?.friends.contains(where: { $0.id == friend.id }) ?? false) {
                                self?.friends.append(friend)
                            }
                        }
                    }
                }
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
                return
            }
            self?.fetchFriends()
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
