//
//  RecommendationsViewModel.swift
//  Deshi_Store_2207034
//
//  Created by macos on 26/11/26.
//

import Foundation

@MainActor
final class RecommendationsViewModel: ObservableObject {
    @Published private(set) var recommended: Set<String> = []
    @Published private(set) var pending: Set<String> = []
    @Published var errorMessage: String?

    private let service = RecommendationService()
    private let bag = ListenerBag()
    private var userID: String?

    func isRecommended(_ productID: String) -> Bool { recommended.contains(productID) }
    func isPending(_ productID: String) -> Bool { pending.contains(productID) }

    func start(userID: String) {
        self.userID = userID
        bag.set(service.listen(userID: userID) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let ids): self.recommended = ids
                case .failure(let error): self.errorMessage = error.userMessage
                }
            }
        })
    }

    func stop() {
        bag.set(nil)
        recommended = []
        pending = []
        userID = nil
    }

    func toggle(_ product: Product) async {
        guard let userID, !pending.contains(product.id) else { return }
        pending.insert(product.id)
        defer { pending.remove(product.id) }
        let adding = !isRecommended(product.id)
        do {
            try await service.toggle(productID: product.id, userID: userID)
            Log.confirmed(adding ? "recommended product \(product.id)" : "recommendation removed from \(product.id)")
        } catch {
            Log.failed("recommendation for \(product.id)", error)
            errorMessage = error.userMessage
        }
    }
}
