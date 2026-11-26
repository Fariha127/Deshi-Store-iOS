//
//  RecommendationService.swift
//  Deshi_Store_2207034
//
//  Created by macos on 26/11/26.
//

import Foundation
import FirebaseFirestore

enum RecommendationError: LocalizedError {
    case productMissing
    var errorDescription: String? { "This product no longer exists." }
}

/// A user's recommendations live at users/{uid}/recommendations/{productId}.
/// The public counter is products/{productId}.recommendCount, updated in the same transaction.
struct RecommendationService {
    private let db = Firestore.firestore()

    private func collection(_ userID: String) -> CollectionReference {
        db.collection("users").document(userID).collection("recommendations")
    }

    /// Live set of product IDs this user has recommended.
    func listen(userID: String, onChange: @escaping (Result<Set<String>, Error>) -> Void) -> ListenerRegistration {
        collection(userID).addSnapshotListener { snapshot, error in
            if let error { onChange(.failure(error)); return }
            onChange(.success(Set(snapshot?.documents.map { $0.documentID } ?? [])))
        }
    }

    /// Adds the recommendation if the user hasn't made one, otherwise removes it,
    /// and moves the product's counter by exactly +1 / -1, atomically.
    func toggle(productID: String, userID: String) async throws {
        let productRef = db.collection("products").document(productID)
        let recRef = collection(userID).document(productID)

        try await db.runTransactionAsync { transaction, errorPointer -> Any? in
            do {
                let productSnap = try transaction.getDocument(productRef)
                let recSnap = try transaction.getDocument(recRef)
                guard let productData = productSnap.data() else { throw RecommendationError.productMissing }
                let count = (productData["recommendCount"] as? NSNumber)?.intValue ?? 0

                if recSnap.exists {
                    transaction.deleteDocument(recRef)
                    transaction.updateData(["recommendCount": max(count - 1, 0)], forDocument: productRef)
                } else {
                    transaction.setData([
                        "productId": productID,
                        "createdAt": FieldValue.serverTimestamp()
                    ], forDocument: recRef)
                    transaction.updateData(["recommendCount": count + 1], forDocument: productRef)
                }
                return nil
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
        }
    }
}
