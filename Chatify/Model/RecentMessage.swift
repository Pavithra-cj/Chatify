//
//  RecentMessage.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-08.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth

struct RecentMessage: Identifiable {
    
    var id: String { documentId }
    
    let documentId: String
    let message: String
    let fromId: String
    let toId: String
    let profileImageUrl: String
    let displayName: String
    let timestamp: Timestamp
    
    let isEncrypted: Bool
    let senderPublicKey: String
    let recipientPublicKey: String
    
    var chatPartnerId: String {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
    
    var isFromCurrentUser: Bool {
        return fromId == Auth.auth().currentUser?.uid
    }
    
    init(
        documentId: String,
        data: [String: Any]
    ) {
        self.documentId = documentId
        let rawMessage = data[FirebaseConstants.message] as? String ?? ""
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.timestamp = data[FirebaseConstants.timestamp] as? Timestamp ?? Timestamp(date: Date())
        self.isEncrypted = data[FirebaseConstants.isEncrypted] as? Bool ?? false
        self.senderPublicKey = data[FirebaseConstants.senderPublicKey] as? String ?? ""
        self.recipientPublicKey = data[FirebaseConstants.recipientPublicKey] as? String ?? ""
        if isEncrypted {
            if let decrypted = EncryptionManager.shared.decrypt(ciphertext: rawMessage,
                                                                from: fromId,
                                                                to: toId,
                                                                senderPublicKey: senderPublicKey,
                                                                recipientPublicKey: recipientPublicKey) {
                self.message = decrypted
            } else {
                self.message = "🔒 Encrypted message"
            }
        } else {
            self.message = rawMessage
        }
        
        // New schema
        let fromName = data["fromName"] as? String
        let toName = data["toName"] as? String
        let fromProfile = data["fromProfileImageUrl"] as? String
        let toProfile = data["toProfileImageUrl"] as? String
        
        if fromName != nil || toName != nil || fromProfile != nil || toProfile != nil {
            if self.fromId == Auth.auth().currentUser?.uid {
                // Current user sent last message -> show receiver
                self.profileImageUrl = toProfile ?? ""
                self.displayName = toName ?? ""
            } else {
                // Current user received last message -> show sender
                self.profileImageUrl = fromProfile ?? ""
                self.displayName = fromName ?? ""
            }
        } else {
            self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
            self.displayName = data["displayName"] as? String ?? ""
        }
    }
    
    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }
}
