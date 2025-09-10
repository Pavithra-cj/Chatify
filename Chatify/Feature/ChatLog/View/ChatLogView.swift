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
    
    static let emptyScrollToString = "Empty"
    
    var body: some View {
        VStack{
            
            ZStack{
                messageView
                Text(vm.errorMessage)
            }
            
            inputView
            
        }
        .navigationTitle(chatUser?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    struct MessageBubbleView: View {
        let message: ChatMessage
        
        var body: some View{
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
    
    private var messageView: some View {
        ScrollView{
            ScrollViewReader { scrollViewProxy in
                VStack{
                    ForEach(vm.chatMessages) { message in
                        
                        MessageBubbleView(message: message)
                        
                    }
                    
                    HStack{
                        Spacer()
                    }
                    .id(Self.emptyScrollToString)
                }
                .onReceive(vm.$count) { _ in
                    withAnimation(.easeOut(duration: 0.5)){
                        scrollViewProxy
                            .scrollTo(Self.emptyScrollToString, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
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
