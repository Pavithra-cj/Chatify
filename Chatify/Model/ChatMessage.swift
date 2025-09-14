//
//  ChatMessage.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-08.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import CoreLocation

struct ChatMessage: Identifiable {
    var id: String {
        documentId
    }
    
    let documentId: String
    let fromId: String
    let toId: String
    let message: String
    let timestamp: Timestamp
    let messageType: MessageType
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp.dateValue())
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: timestamp.dateValue())
    }
    
    enum MessageType: String {
        case text
        case image
        case location
        
        init(rawValue: String) {
            switch rawValue {
            case "image":
                self = .image
            case "location":
                self = .location
            default:
                self = .text
            }
        }
    }
    
    init(documentId: String, data: [String: Any]){
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.message = data[FirebaseConstants.message] as? String ?? ""
        self.timestamp = data[FirebaseConstants.timestamp] as? Timestamp ?? Timestamp(date: Date())
        self.messageType = MessageType(rawValue: data["messageType"] as? String ?? "text")
    }
    
    static func extractCoordinate(from message: String) -> CLLocationCoordinate2D {
        let components = message.split(separator: ",")
        guard components.count == 2,
              let latitude = Double(components[0]),
              let longitude = Double(components[1]) else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
