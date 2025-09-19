//
//  FriendsView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-18.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if !viewModel.friendRequests.isEmpty {
                    pendingRequestsSection
                }
                
                if !viewModel.friends.isEmpty {
                    friendsListSection
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Friends")
            .refreshable {
                viewModel.fetchFriends()
            }
        }
    }
    
    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pending Requests")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(viewModel.friendRequests) { request in
                FriendRequestRow(request: request) {
                    viewModel.acceptFriendRequest(request)
                } onReject: {
                    viewModel.rejectFriendRequest(request)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
        }
        .padding(.top)
    }
    
    private var friendsListSection: some View {
        List {
            ForEach(viewModel.friends) { friend in
                FriendRow(friend: friend)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Friends Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Scan QR codes to add friends")
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
}

struct FriendRequestRow: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    @State private var senderName: String = ""
    @State private var profileImage: String?
    
    var body: some View {
        HStack {
            // Profile Image
            if let base64String = profileImage,
               let imageData = Data(base64Encoded: base64String),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(senderName)
                    .font(.system(size: 16, weight: .medium))
                Text("Wants to be your friend")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onAccept) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                }
                
                Button(action: onReject) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 24))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onAppear {
            fetchSenderDetails()
        }
    }
    
    private func fetchSenderDetails() {
        Firestore.firestore().collection("user")
            .document(request.fromId)
            .getDocument { snapshot, error in
                if let data = snapshot?.data() {
                    self.senderName = data["name"] as? String ?? ""
                    self.profileImage = data["profileImage"] as? String
                }
            }
    }
}

struct FriendRow: View {
    let friend: Friend
    
    var body: some View {
        HStack {
            if let base64String = friend.profileImageUrl,
               let imageData = Data(base64Encoded: base64String),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(friend.name)
                    .font(.system(size: 16, weight: .medium))
                Text(friend.username)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
