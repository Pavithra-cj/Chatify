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
import UIKit

struct AttachmentOption: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void
}

struct AttachmentOptionsView: View {
    @Environment(\.colorScheme) var colorScheme
    let options: [AttachmentOption]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(options) { option in
                        Button(action: option.action) {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: option.icon)
                                            .font(.system(size: 24))
                                            .foregroundStyle(.white)
                                    )
                                Text(option.text)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            .frame(height: 220)
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
    }
}

struct ChatLogView: View {
    let chatUser: ChatUser?
    
    @ObservedObject var vm: ChatLogViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showMediaPicker = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showLocationPicker = false
    @State private var showAttachmentOptions = false
    @State private var showCamera = false
    @State private var isRequestingLocation = false
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    static let emptyScrollToString = "Empty"
    
    private func shareLocation() {
        guard !vm.isSendingLocation else { return }
        isRequestingLocation = true
        LocationManager.shared.requestSingleLocation { result in
            DispatchQueue.main.async {
                self.isRequestingLocation = false
                switch result {
                case .success(let loc):
                    self.vm.sendLocation(loc.coordinate)
                case .failure(let error):
                    switch error {
                    case .denied: vm.errorMessage = "Location permission denied"
                    case .restricted: vm.errorMessage = "Location access restricted"
                    case .timeout: vm.errorMessage = "Location request timed out"
                    case .unavailable: vm.errorMessage = "Location unavailable"
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.gradient)
            }
            messageListView
            inputBarView
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private var chatHeader: some View {
        HStack(spacing: 16) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
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
    
    private var attachmentOptions: [AttachmentOption] {
        [
            AttachmentOption(
                icon: "camera.fill",
                text: "Camera",
                color: .gray,
                action: { showCamera = true }
            ),
            AttachmentOption(
                icon: "photo.fill",
                text: "Photos",
                color: .blue,
                action: { showImagePicker = true }
            ),
            AttachmentOption(
                icon: "face.smiling.fill",
                text: "Stickers",
                color: .purple,
                action: { }
            ),
            AttachmentOption(
                icon: "waveform",
                text: "Audio",
                color: .orange,
                action: { }
            ),
            AttachmentOption(
                icon: "location.fill",
                text: "Location",
                color: .green,
                action: { shareLocation() }
            )
        ]
    }
    
    private var inputBarView: some View {
        VStack(spacing: 0) {
            if showAttachmentOptions {
                AttachmentOptionsView(options: attachmentOptions)
                    .transition(.move(edge: .bottom))
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showAttachmentOptions.toggle()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue)
                        .rotationEffect(.degrees(showAttachmentOptions ? 45 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showAttachmentOptions)
                }
                .disabled(vm.isUploadingImage || vm.isSendingLocation)
                .sheet(isPresented: $showCamera) {
                    ImagePicker(image: $selectedImage, sourceType: .camera)
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
                }
                
                if let image = selectedImage {
                    ZStack(alignment: .center) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipped()
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        if vm.isUploadingImage, let progress = vm.imageUploadProgress {
                            ZStack {
                                Color.black.opacity(0.55)
                                VStack(spacing: 4) {
                                    ProgressView(value: progress)
                                        .progressViewStyle(.linear)
                                        .tint(.white)
                                        .frame(width: 40)
                                    Text("\(Int(progress * 100))%")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .padding(6)
                            }
                            .cornerRadius(10)
                        } else {
                            Button(action: { if !vm.isUploadingImage { selectedImage = nil } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                                    .background(Color.black.opacity(0.25).clipShape(Circle()))
                            }
                            .padding(4)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        }
                    }
                    .padding(.leading, 4)
                    .animation(.easeInOut, value: vm.imageUploadProgress)
                }
                
                CustomTextField(text: $vm.chatText, placeholder: "Message")
                
                if vm.isUploadingImage || vm.isSendingLocation || isRequestingLocation {
                    VStack(spacing: 2) {
                        if vm.isUploadingImage, let progress = vm.imageUploadProgress {
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: 32, height: 32)
                    }
                } else if !vm.chatText.isEmpty || selectedImage != nil {
                    Button(action: {
                        if let image = selectedImage {
                            vm.sendImage(image) {
                                // Clear preview after upload completion
                                selectedImage = nil
                            }
                        } else {
                            vm.handleSendMessage()
                        }
                        showAttachmentOptions = false
                    }) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                    }
                    .disabled(vm.isUploadingImage || vm.isSendingLocation)
                    .opacity(vm.isUploadingImage || vm.isSendingLocation ? 0.5 : 1)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
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
            }
            
            if !isFromCurrentUser { Spacer() }
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        switch message.messageType {
        case .text:
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.message)
                Text(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))
                    .font(.system(size: 11))
                    .foregroundStyle(isFromCurrentUser ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isFromCurrentUser ? Color.blue : (colorScheme == .dark ? Color(.systemGray5) : Color.white))
            .foregroundStyle(isFromCurrentUser ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        case .image:
            if let imageUrl = URL(string: message.message) {
                VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } placeholder: {
                        ProgressView()
                    }
                    Text(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))
                        .font(.system(size: 11))
                        .foregroundStyle(isFromCurrentUser ? .white.opacity(0.8) : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                }
                .padding(6)
                .background(isFromCurrentUser ? Color.blue : (colorScheme == .dark ? Color(.systemGray5) : Color.white))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        case .location:
            let coord = ChatMessage.extractCoordinate(from: message.message)
            Button(action: { openMap(for: coord) }) {
                VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                    ZStack(alignment: .topTrailing) {
                        LocationPreview(coordinate: coord)
                            .frame(width: 200, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        Image(systemName: "map.fill")
                            .font(.system(size: 14))
                            .padding(6)
                            .background(Color.black.opacity(0.4))
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                            .padding(6)
                    }
                    Text(message.timestamp.dateValue().formatted(.dateTime.hour().minute()))
                        .font(.system(size: 11))
                        .foregroundStyle(isFromCurrentUser ? .white.opacity(0.8) : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                }
                .padding(6)
                .background(isFromCurrentUser ? Color.blue : (colorScheme == .dark ? Color(.systemGray5) : Color.white))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .disabled(coord.latitude == 0 && coord.longitude == 0)
        }
    }
    
    private func openMap(for coordinate: CLLocationCoordinate2D) {
        guard coordinate.latitude != 0 || coordinate.longitude != 0 else { return }
        let urlString = "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=Shared%20Location"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
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

extension MessageBubble {
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
