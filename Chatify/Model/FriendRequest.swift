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