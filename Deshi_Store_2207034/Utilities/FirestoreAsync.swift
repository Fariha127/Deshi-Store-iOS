import Foundation
import FirebaseFirestore

extension Firestore {
    /// Firebase 9.6.0 has no async runTransaction, so wrap the completion-handler version.
    func runTransactionAsync(_ block: @escaping (Transaction, NSErrorPointer) -> Any?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.runTransaction(block) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
