import Foundation
import FirebaseFirestore

struct FavouriteService {
    private let db = Firestore.firestore()

    private func collection(_ userID: String) -> CollectionReference {
        db.collection("users").document(userID).collection("favourites")
    }

    func listen(userID: String, onChange: @escaping (Result<[Favourite], Error>) -> Void) -> ListenerRegistration {
        collection(userID).addSnapshotListener { snapshot, error in
            if let error { onChange(.failure(error)); return }
            let items = snapshot?.documents.map {
                Favourite(id: $0.documentID, data: $0.data(with: .estimate))
            } ?? []
            onChange(.success(items))
        }
    }

    func add(productID: String, userID: String) async throws {
        try await collection(userID).document(productID).setData([
            "productId": productID,
            "addedAt": FieldValue.serverTimestamp()
        ])
    }

    func remove(productID: String, userID: String) async throws {
        try await collection(userID).document(productID).delete()
    }
}
