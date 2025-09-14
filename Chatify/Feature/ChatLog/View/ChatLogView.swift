//
//  ChatLogView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-09.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ChatLogView: View {
    let chatUser: ChatUser?
    
    @ObservedObject var vm: ChatLogViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    static let emptyScrollToString = "Empty"
    
    var body: some View {
        VStack{
            
            chatHeader
            
//            ZStack{
//                messageView
//                Text(vm.errorMessage)
//            }
            messageListView
            
            inputBarView
            
        }
//        .navigationTitle(chatUser?.name ?? "")
//        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
    }
    
    private var chatHeader: some View {
        HStack(spacing: 16) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.primary)
            }
            
            if let base64String = chatUser?.profileImage,
               let imageData = Data(base64Encoded: base64String),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.secondary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(chatUser?.name ?? "")
                    .font(.headline)
                Text("Online")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            
            Spacer()
            
            Button(action: { }) {
                Image(systemName: "video")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.primary)
            }
            
            Button(action: { }) {
                Image(systemName: "phone")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.primary)
            }
            
            Button(action: { }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.primary)
            }
        }
        .padding()
        .background(
            colorScheme == .dark ? Color.black : Color.white
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 5)
    }
    
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(vm.chatMessages) { message in
                        MessageBubbleView(message: message)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    HStack { Spacer() }
                        .id(Self.emptyScrollToString)
                }
            }
            .background(Color(.systemGroupedBackground))
            .onReceive(vm.$count) { _ in
                withAnimation(.spring()) {
                    proxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                }
            }
        }
    }
    
    struct MessageBubbleView: View {
        let message: ChatMessage
        @Environment(\.colorScheme) var colorScheme
        
        var isFromCurrentUser: Bool {
            message.fromId == Auth.auth().currentUser?.uid
        }
        
        var body: some View {
            HStack {
                if isFromCurrentUser { Spacer() }
                
                Text(message.message)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        isFromCurrentUser ?
                        Color.blue :
                            (colorScheme == .dark ? Color(.systemGray5) : Color.white)
                    )
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 5)
                
                if !isFromCurrentUser { Spacer() }
            }
        }
    }
    
    private var inputBarView: some View {
        HStack(spacing: 12) {
            Button(action: { }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
            }
            
            Button(action: { }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.gray)
            }
            
            CustomTextField(text: $vm.chatText, placeholder: "Message")
            
            if !vm.chatText.isEmpty {
                Button(action: {
                    vm.handleSendMessage()
                }) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            colorScheme == .dark ? Color.black : Color.white
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: -5)
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.gray)
                    .padding(.leading, 16)
            }
            
            TextField("", text: $text)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationView{
        ChatLogView(chatUser: .init(data: ["uid": "dgVlm86ZEefGgWW5T7PPM8VFuwG3", "email": "test8@gmail.com", "username": "Testperson3", "name": "Test Person 3"]))
    }
}
