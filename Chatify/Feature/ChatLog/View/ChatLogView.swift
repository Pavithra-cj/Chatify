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
        @State private var showTime = false
        
        var isCurrentUser: Bool {
            message.fromId == Auth.auth().currentUser?.uid
        }
        
        var body: some View {
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                HStack {
                    if isCurrentUser { Spacer(minLength: 60) }
                    
                    VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                        // Message Bubble
                        HStack {
                            if !isCurrentUser {
                                Text(message.message)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text(message.message)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background {
                            if isCurrentUser {
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                Color(.systemGray5)
                            }
                        }
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: isCurrentUser ? 20 : 4,
                                bottomLeadingRadius: 20,
                                bottomTrailingRadius: isCurrentUser ? 4 : 20,
                                topTrailingRadius: 20
                            )
                        )
                        .shadow(
                            color: .black.opacity(0.05),
                            radius: 8,
                            x: 0,
                            y: 2
                        )
                        
                        // Timestamp
                        if showTime {
                            Text(formatTimestamp(message.timestamp))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                        }
                    }
                    
                    if !isCurrentUser { Spacer(minLength: 60) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showTime.toggle()
                }
            }
        }
        
        private func formatTimestamp(_ timestamp: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
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
                    // Date Header
                    Text("Today")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 16)
                    
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
        VStack(spacing: 0) {
            // Input Container
            HStack(spacing: 12) {
                // Attachment Button
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .background(.white, in: Circle())
                }
                
                // Text Input
                HStack(spacing: 8) {
                    // Text Field
                    TextField("Message", text: $vm.chatText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...6)
                        .onChange(of: vm.chatText) { _, newValue in
                            // Simulate typing indicator
                            isTyping = !newValue.isEmpty
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isTyping = false
                            }
                        }
                    
                    // Send Button
                    Button(action: {
                        vm.handleSendMessage()
                        isTextFieldFocused = false
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(vm.chatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                            .scaleEffect(vm.chatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 1.0 : 1.1)
                            .animation(.easeInOut(duration: 0.2), value: vm.chatText.isEmpty)
                    }
                    .disabled(vm.chatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.background, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(.separator, lineWidth: 0.5)
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
    }
}

#Preview {
    NavigationView{
        ChatLogView(chatUser: .init(data: ["uid": "dgVlm86ZEefGgWW5T7PPM8VFuwG3", "email": "test8@gmail.com", "username": "Testperson3", "name": "Test Person 3"]))
    }
}
