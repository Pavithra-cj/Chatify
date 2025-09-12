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
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    @ObservedObject var vm: ChatLogViewModel
    
    @State private var keyboardHeight: CGFloat = 0
    @State private var isTyping = false
    @FocusState private var isTextFieldFocused: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    static let emptyScrollToString = "Empty"
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0){
                
                customNavigationHeader
                
                messageView
                    .background(
                        LinearGradient(
                            colors: [
                                Color(.systemBackground),
                                Color(.systemGray6).opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                inputView
                    .background(
                        .ultraThinMaterial,
                        in: Rectangle()
                    )
                
            }
//            .navigationTitle(chatUser?.name ?? "")
//            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    keyboardHeight = keyboardFrame.cgRectValue.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
        }
    }
    
    struct MessageBubbleView: View {
        let message: ChatMessage
        
        var body: some View {
            VStack{
                if message.fromId == Auth.auth().currentUser?.uid {
                    HStack{
                        Spacer()
                        
                        HStack{
                            Text(message.message)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                } else {
                    HStack{
                        HStack{
                            Text(message.message)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    private var customNavigationHeader: some View {
        HStack (spacing: 12) {
            
            //Back Button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            //Profile Image
            AsyncImage(url: URL(string: chatUser?.profileImage ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Text(chatUser?.name.prefix(1) ?? "?")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            //User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(chatUser?.name ?? "Unknown")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Online")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(.separator),
            alignment: .bottom
        )
    }
    
    private var messageView: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    
                    ForEach(vm.chatMessages) { message in
                        MessageBubbleView(message: message)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    
                    // Scroll Anchor
                    Color.clear
                        .frame(height: 1)
                        .id(Self.emptyScrollToString)
                }
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onReceive(vm.$count) { _ in
                withAnimation(.easeOut(duration: 0.5)) {
                    scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                }
            }
        }
    }
    
    private var inputView: some View {
        HStack(spacing: 16){
            
            Image(systemName: "plus.circle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            
            HStack{
                ZStack(alignment: .leading) {
                    if vm.chatText.isEmpty {
                        Text("Text Message")
                            .foregroundColor(Color(.darkGray))
                            .padding(.leading, 12)
                            .padding(.top, 8)
                    }
                    
                    TextEditor(text: $vm.chatText)
                        .foregroundColor(Color(.darkGray))
                        .padding(.leading, 4)
                        .frame(height: 40)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(.darkGray), lineWidth: 1)
                )
                
                Button{
                    vm.handleSendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                }
            }
            
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView{
        ChatLogView(chatUser: .init(data: ["uid": "dgVlm86ZEefGgWW5T7PPM8VFuwG3", "email": "test8@gmail.com", "username": "Testperson3", "name": "Test Person 3"]))
    }
}
