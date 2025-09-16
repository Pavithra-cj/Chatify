//
//  Friend.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-17.
//

import Foundation

struct Friend: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let email: String
    let name: String
    let profileImageUrl: String?
    
    var dictionary: [String: Any] {
        return [
            "userId": userId,
            "username": username,
            "email": email,
            "name": name,
            "profileImageUrl": profileImageUrl ?? ""
        ]
    }
}
