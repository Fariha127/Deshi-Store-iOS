import Foundation
import FirebaseFirestore

struct Review: Identifiable, Hashable {
    let id: String          // equals userId: one review per user per product
    let userId: String
    let userName: String
    let rating: Int
    let comment: String
    let createdAt: Date

    init?(id: String, data: [String: Any]) {
        guard let userId = data["userId"] as? String,
              let rating = (data["rating"] as? NSNumber)?.intValue else { return nil }
        self.id = id
        self.userId = userId
        self.userName = data["userName"] as? String ?? "Anonymous"
        self.rating = rating
        self.comment = data["comment"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}
