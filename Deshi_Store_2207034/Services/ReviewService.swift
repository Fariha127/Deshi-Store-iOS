import Foundation
import FirebaseFirestore

enum ReviewError: LocalizedError {
    case productMissing
    var errorDescription: String? { "This product no longer exists." }
}

struct ReviewService {
    private let db = Firestore.firestore()

    private func reviews(_ productID: String) -> CollectionReference {
        db.collection("products").document(productID).collection("reviews")
    }

    /// Firebase 9.6.0 has no async runTransaction, so wrap the completion-handler version.
    private func runTransaction(_ block: @escaping (Transaction, NSErrorPointer) -> Any?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.runTransaction(block) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func listen(productID: String, onChange: @escaping (Result<[Review], Error>) -> Void) -> ListenerRegistration {
        reviews(productID).order(by: "createdAt", descending: true).addSnapshotListener { snapshot, error in
            if let error { onChange(.failure(error)); return }
            let items = snapshot?.documents.compactMap {
                Review(id: $0.documentID, data: $0.data(with: .estimate))
            } ?? []
            onChange(.success(items))
        }
    }

    /// Creates or replaces the user's review and updates the product's
    /// averageRating / reviewCount in a single atomic transaction.
    func submit(productID: String, user: AppUser, rating: Int, comment: String) async throws {
        let productRef = db.collection("products").document(productID)
        let reviewRef = productRef.collection("reviews").document(user.id)

        try await runTransaction { transaction, errorPointer -> Any? in
            do {
                let productSnap = try transaction.getDocument(productRef)
                let oldReviewSnap = try transaction.getDocument(reviewRef)
                guard let productData = productSnap.data() else { throw ReviewError.productMissing }

                var count = (productData["reviewCount"] as? NSNumber)?.intValue ?? 0
                var total = ((productData["averageRating"] as? NSNumber)?.doubleValue ?? 0) * Double(count)

                if oldReviewSnap.exists, let old = (oldReviewSnap.data()?["rating"] as? NSNumber)?.intValue {
                    total -= Double(old)          // editing: replace the old rating
                } else {
                    count += 1                    // new review
                }
                total += Double(rating)

                transaction.setData([
                    "reviewId": user.id,
                    "userId": user.id,
                    "userName": user.name,
                    "rating": rating,
                    "comment": comment,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: reviewRef)
                transaction.updateData([
                    "averageRating": total / Double(count),
                    "reviewCount": count
                ], forDocument: productRef)
                return nil
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
        }
    }

    func deleteReview(productID: String, userID: String) async throws {
        let productRef = db.collection("products").document(productID)
        let reviewRef = productRef.collection("reviews").document(userID)

        try await runTransaction { transaction, errorPointer -> Any? in
            do {
                let productSnap = try transaction.getDocument(productRef)
                let reviewSnap = try transaction.getDocument(reviewRef)
                guard reviewSnap.exists, let productData = productSnap.data() else { return nil }

                let old = (reviewSnap.data()?["rating"] as? NSNumber)?.intValue ?? 0
                let count = max((productData["reviewCount"] as? NSNumber)?.intValue ?? 1, 1)
                let total = ((productData["averageRating"] as? NSNumber)?.doubleValue ?? 0) * Double(count) - Double(old)
                let newCount = count - 1

                transaction.deleteDocument(reviewRef)
                transaction.updateData([
                    "averageRating": newCount > 0 ? total / Double(newCount) : 0.0,
                    "reviewCount": newCount
                ], forDocument: productRef)
                return nil
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
        }
    }
}
