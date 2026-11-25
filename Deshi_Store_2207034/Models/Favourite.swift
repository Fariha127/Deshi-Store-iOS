import Foundation
import FirebaseFirestore

struct Favourite: Identifiable, Hashable {
    let id: String          // productId
    let addedAt: Date

    init(id: String, data: [String: Any]) {
        self.id = id
        self.addedAt = (data["addedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}
