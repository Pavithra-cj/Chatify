//
//  MainMessageView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-08-20.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct MainMessageView: View {
    @StateObject var vm = MainMessagesViewModel()
    @State var shouldShowLogOutOptions = false
    @State var shouldShowNewMessageScreen = false
    @State var shouldShowQRCodeScanner = false
    @State var shouldShowDisplayQRCode = false
    @State var chatUser: ChatUser?
    @State private var shouldShowFriends = false
    
    @Binding var showQRCode: Bool
    @Binding var showScanner: Bool
    let onChatSelected: (ChatUser) -> Void
    
    @ObservedObject private var scannerViewModel = QRCodeScannerViewModel()
    
    private var customNavBar: some View {
        HStack {
            if let base64String = vm.chatUser?.profileImage,
               let imageData = Data(base64Encoded: base64String),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(50)
                    .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color.black, lineWidth: 1))
                    .shadow(radius: 5)
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vm.chatUser?.username ?? "Username")")
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    shouldShowFriends = true
                } label: {
                    Image(systemName: "person.2")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.label))
                }

                Button {
                    showQRCode.toggle()
                } label: {
                    Image(systemName: "qrcode")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.label))
                }
                
                Button {
                    showScanner.toggle()
                } label: {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.label))
                }
            }
        }
        .padding()
        .sheet(isPresented: $showQRCode) {
            QRCodeDisplayView()
        }
        .sheet(isPresented: $showScanner) {
            QRCodeScannerView(viewModel: scannerViewModel)
                .onChange(of: scannerViewModel.scannedCode) { oldValue, newValue in
                    if let code = newValue {
                        handleScannedCode(code)
                    }
                }
        }
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(
                title: Text("Settings"),
                message: Text("What do you want to do?"),
                buttons: [
                    .destructive(Text("Sign Out"), action: {
                        print("Handle Sign out")
                        vm.handleSignOut()
                    }),
                    //                    .default(Text("DEFAULT BUTTON")),
                    .cancel()
                ]
            )
        }
        .fullScreenCover(
            isPresented: $vm.isUserCurrentlyLoggedOut,
            onDismiss: nil,
        ){
            LoginView(alreadyLoggedIn: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
            })
        }
        .fullScreenCover(isPresented: $shouldShowFriends) {
            NavigationStack {
                FriendsView()
                    .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { shouldShowFriends = false } } }
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private var messagesView: some View{
        ScrollView{
            ForEach(vm.recentMessages) { recentMessage in
                VStack{
                    Button(action: {
                        let currentUserId = Auth.auth().currentUser?.uid ?? ""
                        let chatUserId = recentMessage.fromId == currentUserId ? recentMessage.toId : recentMessage.fromId
                        let chatUserData: [String: Any] = [
                            "uid": chatUserId,
                            "name": recentMessage.displayName,
                            "username": recentMessage.displayName,
                            "email": "",
                            "profileImage": recentMessage.profileImageUrl
                        ]
                        let user = ChatUser(data: chatUserData)
                        self.chatUser = user
                        onChatSelected(user)
                    }) {
                        HStack(spacing: 16){
                            if let imageData = Data(base64Encoded: recentMessage.profileImageUrl),
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipped()
                                    .cornerRadius(50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 44)
                                            .stroke(Color.black, lineWidth: 1)
                                    )
                                    .shadow(radius: 5)
                            } else {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                            }
                            VStack(alignment: .leading, spacing: 8){
                                Text(recentMessage.displayName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(.label))
                                Text(recentMessage.message)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.darkGray))
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Text(recentMessage.timeAgoDisplay)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)
            }.padding(.bottom, 50)
        }
    }
    
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.blue)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
        .padding([.trailing, .bottom], 20)
    }
    
    private var friendRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Friend Requests")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.friendRequests) { request in
                        FriendRequestCard(request: request) {
                            vm.acceptFriendRequest(request)
                        } onReject: {
                            vm.rejectFriendRequest(request)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 100)
            
            Divider()
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                customNavBar
                
                if !vm.friendRequests.isEmpty {
                    friendRequestsSection
                }
                
                messagesView
            }
            
            newMessageButton
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen, onDismiss: nil) {
            CreateNewMessageView(didSelectUser: { friend in
                let user = ChatUser(data: [
                    "uid": friend.userId,
                    "email": friend.email,
                    "username": friend.username,
                    "profileImage": friend.profileImageUrl ?? "",
                    "name": friend.name
                ])
                self.chatUser = user
                onChatSelected(user)
                self.shouldShowNewMessageScreen = false
            })
        }
    }
    
    private func handleScannedCode(_ code: String) {
        // Add friend using scanned code
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let friendId = code.components(separatedBy: "_").first ?? ""
        
        let db = Firestore.firestore()
        db.collection("user").document(currentUserId).updateData([
            "friends": FieldValue.arrayUnion([friendId])
        ])
        
        showScanner = false
    }
}

struct FriendRequestCard: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    @State private var senderName: String = ""
    
    var body: some View {
        VStack {
            Text(senderName)
                .font(.subheadline)
                .lineLimit(1)
            
            HStack(spacing: 8) {
                Button(action: onAccept) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Button(action: onReject) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
        .onAppear {
            fetchSenderName()
        }
    }
    
    private func fetchSenderName() {
        Firestore.firestore().collection("user")
            .document(request.fromId)
            .getDocument { snapshot, error in
                if let data = snapshot?.data(), let name = data["name"] as? String {
                    self.senderName = name
                }
            }
    }
}

#Preview {
    MainMessageView(showQRCode: .constant(false), showScanner: .constant(false), onChatSelected: { _ in })
}
