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
    @State var shouldShowLogOutOptions = false
    @State var shouldShowNewChatOptions = false
    @State var shouldNavigateToChatLogView = false
    
    @Binding var showQRCode: Bool
    @Binding var showScanner: Bool
    
    @ObservedObject private var vm = MainMessagesViewModel()
    @StateObject private var scannerViewModel = QRCodeScannerViewModel()
    
    @State var chatUser: ChatUser?
    
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
                        
                        self.chatUser = ChatUser(data: chatUserData)
                        self.shouldNavigateToChatLogView = true
                        print("Go to chat log with user: \(self.chatUser?.uid ?? "" )")
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
    
    private var newMessageButton: some View{
        Button {
            shouldShowNewChatOptions.toggle()
        }
        label: {
            HStack{
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewChatOptions, onDismiss: nil){
            CreateNewMessageView(didSelectUser: { friend in
                print(friend.email)
                self.shouldNavigateToChatLogView.toggle()
                // Convert Friend to ChatUser
                self.chatUser = ChatUser(data: [
                    "uid": friend.userId,
                    "email": friend.email,
                    "username": friend.username,
                    "profileImage": friend.profileImageUrl ?? "",
                    "name": friend.name
                ])
            })
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                //Custom Navigation Bar
                customNavBar
                
                //Messages View
                messagesView
            }
            .overlay(
                newMessageButton, alignment: .bottom
            )
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $shouldNavigateToChatLogView) {
                if let chatUser = chatUser {
                    ChatLogView(chatUser: chatUser)
                }
            }
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

#Preview {
    MainMessageView(showQRCode: .constant(false), showScanner: .constant(false))
}
