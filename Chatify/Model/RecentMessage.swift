//
//  RecentMessage.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-08.
//

import Foundation
import SwiftUI
import Firebase

struct RecentMessage: Identifiable {
    
    var id: String { documentId }
    
    let documentId: String
    let message: String
    let fromId: String
    let toId: String
    let profileImageUrl: String
    let displayName: String
    let timestamp: Timestamp
    
    init(
        documentId: String,
        data: [String: Any]
    ) {
        self.documentId = documentId
        self.message = data[FirebaseConstants.message] as? String ?? ""
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        self.displayName = data["displayName"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(
            date: Date()
        )
    }
    
    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }
    
}
