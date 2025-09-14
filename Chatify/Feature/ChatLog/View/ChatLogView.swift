//
//  ChatLogView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-09.
//

import SwiftUI
import Firebase
import FirebaseAuth
import CoreLocation
import MapKit

struct ChatLogView: View {
    let chatUser: ChatUser?
    
    @ObservedObject var vm: ChatLogViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var showMediaPicker = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showLocationPicker = false
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    static let emptyScrollToString = "Empty"
    
    private func shareLocation() {
        LocationManager.shared.requestLocation()
        if let location = LocationManager.shared.location {
            vm.sendLocation(location.coordinate)
        }
    }
    
    var body: some View {
        VStack{
            
            chatHeader
            
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
                LazyVStack(spacing: 0) {
                    ForEach(groupedMessages.keys.sorted(), id: \.self) { date in
                        Section {
                            DateSeparatorView(date: date)
                            
                            ForEach(groupedMessages[date] ?? []) { message in
                                MessageBubble(message: message, vm: vm)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    
                    HStack { Spacer() }
                        .id(Self.emptyScrollToString)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .onReceive(vm.$count) { _ in
                withAnimation(.spring()) {
                    proxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                }
            }
        }
    }
    
    private var groupedMessages: [Date: [ChatMessage]] {
        Dictionary(grouping: vm.chatMessages) { message in
            Calendar.current.startOfDay(for: message.timestamp.dateValue())
        }
    }
    
//    struct MessageBubbleView: View {
//        let message: ChatMessage
//        @Environment(\.colorScheme) var colorScheme
//        
//        var isFromCurrentUser: Bool {
//            message.fromId == Auth.auth().currentUser?.uid
//        }
//        
//        var body: some View {
//            HStack {
//                if isFromCurrentUser { Spacer() }
//                
//                Text(message.message)
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 12)
//                    .background(
//                        isFromCurrentUser ?
//                        Color.blue :
//                            (colorScheme == .dark ? Color(.systemGray5) : Color.white)
//                    )
//                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
//                    .clipShape(
//                        RoundedRectangle(cornerRadius: 20)
//                    )
//                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 5)
//                
//                if !isFromCurrentUser { Spacer() }
//            }
//        }
//    }
    
    struct MessageBubble: View {
        let message: ChatMessage
        @ObservedObject var vm: ChatLogViewModel
        @Environment(\.colorScheme) var colorScheme
        
        var isFromCurrentUser: Bool {
            message.fromId == Auth.auth().currentUser?.uid
        }
        
        var body: some View {
            HStack {
                if isFromCurrentUser { Spacer() }
                
                VStack(alignment: isFromCurrentUser ? .trailing : .leading) {
                    messageContent
                    Text(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                
                if !isFromCurrentUser { Spacer() }
            }
        }
        
        @ViewBuilder
        private var messageContent: some View {
            switch message.messageType {
            case .text:
                Text(message.message)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isFromCurrentUser ? Color.blue : (colorScheme == .dark ? Color(.systemGray5) : Color.white))
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            case .image:
                if let imageUrl = URL(string: message.message) {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } placeholder: {
                        ProgressView()
                    }
                }
            case .location:
                LocationPreview(coordinate: ChatMessage.extractCoordinate(from: message.message))
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    private var inputBarView: some View {
        HStack(spacing: 12) {
            Button(action: { showMediaPicker.toggle() }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
            }
            .actionSheet(isPresented: $showMediaPicker) {
                ActionSheet(title: Text("Share Media"), buttons: [
                    .default(Text("Photo Library")) { showImagePicker.toggle() },
                    .default(Text("Share Location")) { shareLocation() },
                    .cancel()
                ])
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            
            CustomTextField(text: $vm.chatText, placeholder: "Message")
            
            if !vm.chatText.isEmpty || selectedImage != nil {
                Button(action: {
                    if let image = selectedImage {
                        vm.sendImage(image)
                    } else {
                        vm.handleSendMessage()
                    }
                    selectedImage = nil
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
    }
}

struct DateSeparatorView: View {
    let date: Date
    
    var body: some View {
        Text(date.formatted(.dateTime.day().month()))
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
            )
            .padding(.vertical, 8)
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

struct LocationPreview: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }
}

extension ChatLogView.MessageBubble {
    var shouldShowDate: Bool {
        guard let currentIndex = vm.chatMessages.firstIndex(where: { $0.id == message.id }) else {
            return false
        }
        
        // Show date for first message
        if currentIndex == 0 {
            return true
        }
        
        let previousMessage = vm.chatMessages[currentIndex - 1]
        let currentDate = Calendar.current.startOfDay(for: message.timestamp.dateValue())
        let previousDate = Calendar.current.startOfDay(for: previousMessage.timestamp.dateValue())
        
        // Show date if messages are from different days
        return currentDate != previousDate
    }
}

#Preview {
    NavigationView{
        ChatLogView(chatUser: .init(data: ["uid": "dgVlm86ZEefGgWW5T7PPM8VFuwG3", "email": "test8@gmail.com", "username": "Testperson3", "name": "Test Person 3"]))
    }
}
