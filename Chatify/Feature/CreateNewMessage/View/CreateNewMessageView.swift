//
//  CreateNewMessageView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-09.
//

import SwiftUI

struct FriendRowView: View {
    let friend: Friend
    let onSelect: (ChatUser) -> Void
    
    var body: some View {
        Button {
            let chatUser = ChatUser(data: [
                "uid": friend.userId,
                "email": friend.email,
                "profileImageUrl": friend.profileImageUrl ?? ""
            ])
            onSelect(chatUser)
        } label: {
            HStack(spacing: 16) {
                ProfileImageView(imageUrl: friend.profileImageUrl)
                UserInfoView(name: friend.name, email: friend.email)
                Spacer()
            }
            .padding(.horizontal)
        }
        Divider()
            .padding(.vertical, 8)
    }
}

struct ProfileImageView: View {
    let imageUrl: String?
    
    var body: some View {
        if let profileUrl = imageUrl,
           let url = URL(string: profileUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(50)
                    .overlay(RoundedRectangle(cornerRadius: 44)
                        .stroke(Color.black, lineWidth: 2))
                    .shadow(radius: 5)
            } placeholder: {
                defaultProfileImage
            }
        } else {
            defaultProfileImage
        }
    }
    
    private var defaultProfileImage: some View {
        Image(systemName: "person.fill")
            .resizable()
            .frame(width: 48, height: 48)
            .clipShape(Circle())
    }
}

struct UserInfoView: View {
    let name: String
    let email: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.label))
            Text(email)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color(.label))
        }
    }
}

struct CreateNewMessageView: View {
    let didSelectNewUser: (ChatUser) -> ()
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(vm.users) { friend in
                    FriendRowView(friend: friend) { chatUser in
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(chatUser)
                    }
                }
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            .onAppear {
                vm.fetchFriends()
            }
        }
    }
}

#Preview {
    CreateNewMessageView { user in
        print("Selected user: \(user)")
    }
}
