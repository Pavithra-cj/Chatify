//
//  MainMessageView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-08-20.
//

import SwiftUI
import SDWebImageSwiftUI

struct MainMessageView: View {
    @State var shouldShowLogOutOptions = false
    @State var shouldShowNewChatOptions = false
    @State var shouldNavigateToChatLogView = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    @State var chatUser: ChatUser?
    
    private var customNavBar: some View {
        HStack{
            
            //MARK: Only work with Firebase Storage
            //            WebImage(url: URL(string: vm.chatUser?.profileImage ?? ""))
            //                .resizable()
            //                .scaledToFill()
            //                .frame(width: 50, height: 50)
            //                .clipped()
            //                .cornerRadius(50)
            //                .overlay(
            //                    RoundedRectangle(
            //                        cornerRadius: 44
            //                    )
            //                    .stroke(Color.black, lineWidth: 1)
            //                )
            //                .shadow(radius: 5)
            
            //Since I used base64 encode to store the image in firestore, directly decoding it is the best option.
            
            //MARK: Use this for now. Using Firestore
            
            if let base64String = vm.chatUser?.profileImage,
               let imageData = Data(base64Encoded: base64String),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(50)
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: 44
                        )
                        .stroke(Color.black, lineWidth: 1)
                    )
                    .shadow(radius: 5)
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4){
                Text("\(vm.chatUser?.username ?? "Username")")
                    .font(.system(size: 24, weight: .bold))
                
                HStack{
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }
            Spacer()
            Button{
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
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
                    NavigationLink{
                        Text("Destination")
                    } label: {
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
            CreateNewMessageView(didSelectNewUser: { user in
                print(user.email)
                self.shouldNavigateToChatLogView.toggle()
                self.chatUser = user
            })
        }
    }
    
    var body: some View {
        NavigationView{
            VStack{
                //Custom Navigation Bar
                customNavBar
                
                //Messages View
                messagesView
                
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(chatUser: self.chatUser)
                }
            }
            .overlay(
                newMessageButton, alignment: .bottom
            )
            .navigationBarHidden(true)
            //            .navigationTitle("Main Message View")
        }
    }
}

#Preview {
    MainMessageView()
}
