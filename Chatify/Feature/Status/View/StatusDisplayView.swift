//
//  StatusDisplayView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-19.
//

import SwiftUI

struct StatusDisplayView: View {
    let userStatusGroup: UserStatusGroup
    @State private var currentIndex = 0
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: StatusViewModel
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // Progress bars
                HStack(spacing: 4) {
                    ForEach(0..<userStatusGroup.statuses.count, id: \.self) { index in
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 2)
                                
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: index < currentIndex ? geometry.size.width :
                                           (index == currentIndex ? geometry.size.width * progress : 0),
                                           height: 2)
                                    .animation(.linear, value: progress)
                            }
                        }
                        .frame(height: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Header
                HStack {
                    AsyncImage(url: URL(string: userStatusGroup.userProfileImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(userStatusGroup.username)
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Text(userStatusGroup.statuses[currentIndex].timeAgoString)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Status Image
                Spacer()
                
                AsyncImage(url: URL(string: userStatusGroup.statuses[currentIndex].imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .tint(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    nextStatus()
                }
                
                Spacer()
            }
        }
        .onAppear {
            startTimer()
            // Mark as viewed
            viewModel.markStatusAsViewed(statusId: userStatusGroup.statuses[currentIndex].id)
        }
        .onDisappear {
            stopTimer()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        previousStatus()
                    } else if value.translation.width < -100 {
                        nextStatus()
                    }
                }
        )
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                progress += 0.02
            }
            
            if progress >= 1.0 {
                nextStatus()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func nextStatus() {
        stopTimer()
        
        if currentIndex < userStatusGroup.statuses.count - 1 {
            currentIndex += 1
            progress = 0
            startTimer()
            // Mark new status as viewed
            viewModel.markStatusAsViewed(statusId: userStatusGroup.statuses[currentIndex].id)
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func previousStatus() {
        stopTimer()
        
        if currentIndex > 0 {
            currentIndex -= 1
            progress = 0
            startTimer()
        }
    }
}

#Preview {
    StatusDisplayView(
        userStatusGroup: UserStatusGroup(
            id: "1",
            userId: "user1",
            username: "John Doe",
            userProfileImageUrl: nil,
            statuses: [
                Status(
                    id: "status1",
                    userId: "user1",
                    username: "John Doe",
                    userProfileImageUrl: nil,
                    imageUrl: "https://example.com/image.jpg",
                    timestamp: Date(),
                    viewerIds: []
                )
            ]
        ),
        viewModel: StatusViewModel()
    )
}
