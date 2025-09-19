//
//  Status.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-19.
//

import Foundation
import FirebaseAuth

struct Status: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let userProfileImageUrl: String?
    let imageUrl: String
    let timestamp: Date
    let viewerIds: [String]
    
    var dictionary: [String: Any] {
        return [
            "userId": userId,
            "username": username,
            "userProfileImageUrl": userProfileImageUrl ?? "",
            "imageUrl": imageUrl,
            "timestamp": timestamp,
            "viewerIds": viewerIds
        ]
    }
    
    // Check if status is expired (24 hours)
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 24 * 60 * 60
    }
    
    // Time ago
    var timeAgoString: String {
        let interval = Date().timeIntervalSince(timestamp)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            return "Yesterday"
        }
    }
}

// Group statuses by user
struct UserStatusGroup: Identifiable {
    let id: String
    let userId: String
    let username: String
    let userProfileImageUrl: String?
    let statuses: [Status]
    
    var hasUnviewedStatus: Bool {
        // Check if current user has viewed all statuses
        guard let currentUserId = getCurrentUserId() else { return false }
        return statuses.contains { !$0.viewerIds.contains(currentUserId) }
    }
    
    var latestStatus: Status? {
        statuses.max(by: { $0.timestamp < $1.timestamp })
    }
}

// Helper function to get current user ID
private func getCurrentUserId() -> String? {
    // This should return the current user's ID from your authentication system
    // You may need to adjust this based on how you handle authentication
    return FirebaseAuth.Auth.auth().currentUser?.uid
}
