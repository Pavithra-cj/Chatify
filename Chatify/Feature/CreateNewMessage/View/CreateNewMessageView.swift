//
//  CreateNewMessageView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-09.
//

import SwiftUI
import SDWebImageSwiftUI

struct CreateNewMessageView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateNewMessageViewModel()
    @State private var isRefreshing = false
    let didSelectUser: (Friend) -> Void
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.errorMessage.isEmpty {
                    ForEach(viewModel.users) { user in
                        Button {
                            dismiss()
                            didSelectUser(user)
                        } label: {
                            FriendRowView(friend: user)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                viewModel.refreshFriends()
            }
            .overlay(Group {
                if viewModel.users.isEmpty && viewModel.errorMessage.isEmpty {
                    ContentUnavailableView(
                        "No Friends Yet",
                        systemImage: "person.2",
                        description: Text("Scan someone's QR code to add them as a friend")
                    )
                }
            })
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: NavigationLink(destination: ScannerScreen()) {
                    Image(systemName: "qrcode.viewfinder")
                }
            )
            .onAppear {
                viewModel.refreshFriends()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshFriendsList"))) { _ in
                viewModel.refreshFriends()
            }
        }
    }
}

struct FriendRowView: View {
    let friend: Friend
    
    var body: some View {
        HStack(spacing: 16) {
            if let base64String = friend.profileImageUrl,
               let imageData = Data(base64Encoded: base64String),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(25)
                    .overlay(Circle()
                        .stroke(Color(.label), lineWidth: 1))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.system(size: 16, weight: .semibold))
                Text(friend.email)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.lightGray))
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CreateNewMessageView { user in
        print("Selected user: \(user)")
    }
}
