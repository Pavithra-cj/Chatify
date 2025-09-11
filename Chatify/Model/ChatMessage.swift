//
//  ChatMessage.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-08.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct ChatMessage: Identifiable {
    var id: String {
        documentId
    }
    
    let documentId: String
    let fromId: String
    let toId: String
    let message: String
    let timestamp: Date
    
    init(documentId: String, data: [String: Any]){
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.message = data[FirebaseConstants.message] as? String ?? ""
        
        if let ts = data[FirebaseConstants.timestamp] as? Timestamp {
            self.timestamp = ts.dateValue()
        } else {
            self.timestamp = Date()
        }
    }
}
