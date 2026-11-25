import Foundation
import FirebaseFirestore

struct ProductService {
    private let db = Firestore.firestore()
    private var collection: CollectionReference { db.collection("products") }

    /// Live listener: the UI updates automatically when products or ratings change.
    func listen(onChange: @escaping (Result<[Product], Error>) -> Void) -> ListenerRegistration {
        collection.order(by: "name").addSnapshotListener { snapshot, error in
            if let error { onChange(.failure(error)); return }
            let items = snapshot?.documents.compactMap { Product(id: $0.documentID, data: $0.data()) } ?? []
            onChange(.success(items))
        }
    }

    // MARK: Admin CRUD (enforced by Firestore rules)

    func add(_ draft: ProductDraft) async throws {
        let ref = collection.document()
        try await ref.setData(draft.firestoreData(productID: ref.documentID))
    }

    func update(id: String, with draft: ProductDraft) async throws {
        try await collection.document(id).updateData(draft.firestoreData())
    }

    func delete(id: String) async throws {
        try await collection.document(id).delete()
    }

    /// Creates products that don't exist yet (by slug ID). Returns how many were created.
    func importMissing(_ drafts: [ProductDraft]) async throws -> Int {
        let existing = Set(try await collection.getDocuments().documents.map(\.documentID))
        let batch = db.batch()
        var created = 0
        for draft in drafts where !existing.contains(draft.slug) {
            let id = draft.slug
            batch.setData(draft.firestoreData(productID: id), forDocument: collection.document(id))
            created += 1
        }
        if created > 0 { try await batch.commit() }
        return created
    }
}
