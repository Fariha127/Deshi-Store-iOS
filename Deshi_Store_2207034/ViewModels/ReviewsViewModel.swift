import Foundation

@MainActor
final class ReviewsViewModel: ObservableObject {
    @Published private(set) var reviews: [Review] = []
    @Published private(set) var isLoading = true
    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?

    let productID: String
    private let service = ReviewService()
    private let bag = ListenerBag()

    init(productID: String) { self.productID = productID }

    var averageRating: Double {
        reviews.isEmpty ? 0 : Double(reviews.map(\.rating).reduce(0, +)) / Double(reviews.count)
    }

    /// Number of reviews for each star value (1...5).
    func count(forStars stars: Int) -> Int { reviews.filter { $0.rating == stars }.count }

    func myReview(userID: String?) -> Review? {
        guard let userID else { return nil }
        return reviews.first { $0.userId == userID }
    }

    func start() {
        guard !bag.isActive else { return }
        bag.set(service.listen(productID: productID) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let items): self.reviews = items
                case .failure(let error): self.errorMessage = error.userMessage
                }
            }
        })
    }

    func submit(rating: Int, comment: String, user: AppUser) async -> Bool {
        errorMessage = nil
        guard (1...5).contains(rating) else { errorMessage = "Please choose a star rating."; return false }
        let text = comment.trimmed
        guard text.count >= 5 else { errorMessage = "Write at least 5 characters."; return false }
        guard text.count <= 500 else { errorMessage = "Reviews are limited to 500 characters."; return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await service.submit(productID: productID, user: user, rating: rating, comment: text)
            Log.confirmed("review saved for product \(productID)")
            return true
        } catch {
            Log.failed("review for product \(productID)", error)
            errorMessage = error.userMessage
            return false
        }
    }

    func deleteMyReview(userID: String) async {
        do {
            try await service.deleteReview(productID: productID, userID: userID)
            Log.confirmed("review deleted for product \(productID)")
        } catch {
            Log.failed("delete review \(productID)", error)
            errorMessage = error.userMessage
        }
    }
}
