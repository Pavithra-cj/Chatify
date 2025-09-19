//
//  StatusView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct StatusView: View {
    @StateObject private var viewModel = StatusViewModel()
    @State private var showingStatusDisplay = false
    @State private var selectedStatusGroup: UserStatusGroup?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // My Status Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("My status")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        MyStatusRow(viewModel: viewModel, onOpenStatuses: { group in
                            selectedStatusGroup = group
                            showingStatusDisplay = true
                        })
                    }
                    .padding(.vertical)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 0.5)
                        .padding(.horizontal)
                    
                    // Recent updates
                    if !viewModel.friendsStatusGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recent updates")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.friendsStatusGroups) { statusGroup in
                                    StatusRow(
                                        statusGroup: statusGroup,
                                        onTap: {
                                            selectedStatusGroup = statusGroup
                                            showingStatusDisplay = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Status")
            .onAppear { viewModel.fetchStatuses() }
            .refreshable {
                viewModel.fetchStatuses()
            }
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: $viewModel.selectedImage)
        }
        .fullScreenCover(isPresented: $showingStatusDisplay) {
            if let statusGroup = selectedStatusGroup {
                StatusDisplayView(userStatusGroup: statusGroup, viewModel: viewModel)
            }
        }
        .onChange(of: viewModel.selectedImage) { image in
            if let image = image {
                viewModel.uploadStatus(image: image)
            }
        }
        .alert("Error", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
            Button("OK") {
                viewModel.errorMessage = ""
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct MyStatusRow: View {
    @ObservedObject var viewModel: StatusViewModel
    let onOpenStatuses: (UserStatusGroup) -> Void
    @State private var currentUser: (name: String, profileUrl: String?) = ("", nil)
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                // Profile Image
                AsyncImage(url: URL(string: currentUser.profileUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                // Add button if no status
                if viewModel.currentUserStatuses.isEmpty {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .bold))
                        )
                        .offset(x: 20, y: 20)
                } else {
                    // Status ring
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 66, height: 66)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("My status")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if viewModel.currentUserStatuses.isEmpty {
                    Text("Tap to add status update")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("\(viewModel.currentUserStatuses.first?.timeAgoString ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Camera button
            Button(action: {
                viewModel.showImagePicker = true
            }) {
                Image(systemName: "camera.fill")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            if !viewModel.currentUserStatuses.isEmpty {
                // Show current user's status
                let currentUserGroup = UserStatusGroup(
                    id: Auth.auth().currentUser?.uid ?? "",
                    userId: Auth.auth().currentUser?.uid ?? "",
                    username: currentUser.name.isEmpty ? "You" : currentUser.name,
                    userProfileImageUrl: currentUser.profileUrl,
                    statuses: viewModel.currentUserStatuses
                )
                onOpenStatuses(currentUserGroup)
            } else {
                viewModel.showImagePicker = true
            }
        }
        .onAppear {
            loadCurrentUserInfo()
        }
    }
    
    private func loadCurrentUserInfo() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("user").document(currentUserId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let name = data?["name"] as? String ?? data?["username"] as? String ?? "You"
                let profileUrl = (data?["profileImage"] as? String) ?? (data?["profileImageUrl"] as? String)
                DispatchQueue.main.async {
                    self.currentUser = (name: name, profileUrl: profileUrl)
                }
            }
        }
    }
}

struct StatusRow: View {
    let statusGroup: UserStatusGroup
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                // Profile Image
                AsyncImage(url: URL(string: statusGroup.userProfileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                // Status ring
                Circle()
                    .stroke(
                        statusGroup.hasUnviewedStatus ? Color.green : Color.gray.opacity(0.5),
                        lineWidth: 3
                    )
                    .frame(width: 66, height: 66)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(statusGroup.username)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(statusGroup.latestStatus?.timeAgoString ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    StatusView()
}
