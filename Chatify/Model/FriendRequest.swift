//
//  FriendsView.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-18.
//

import Foundation
import FirebaseFirestore

struct FriendRequest: Identifiable, Codable {
    var id: String
    let fromId: String
    let toId: String
    let timestamp: Date
    var status: RequestStatus
    
    enum RequestStatus: String, Codable {
        case pending
        case accepted
        case rejected
    }
}
