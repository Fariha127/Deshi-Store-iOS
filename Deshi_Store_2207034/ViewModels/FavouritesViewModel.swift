import Foundation

@MainActor
final class FavouritesViewModel: ObservableObject {
    @Published private(set) var favourites: [String: Date] = [:]   // productId -> addedAt
    @Published var errorMessage: String?

    private let service = FavouriteService()
    private let bag = ListenerBag()
    private var userID: String?

    /// Product IDs, most recently added first.
    var orderedIDs: [String] {
        favourites.sorted { $0.value > $1.value }.map(\.key)
    }

    func isFavourite(_ productID: String) -> Bool { favourites[productID] != nil }

    func start(userID: String) {
        self.userID = userID
        bag.set(service.listen(userID: userID) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let items):
                    self.favourites = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.addedAt) })
                case .failure(let error):
                    self.errorMessage = error.userMessage
                }
            }
        })
    }

    func stop() {
        bag.set(nil)
        favourites = [:]
        userID = nil
    }

    func toggle(_ product: Product) async {
        guard let userID else { return }
        do {
            if isFavourite(product.id) {
                try await service.remove(productID: product.id, userID: userID)
                Log.confirmed("favourite removed: \(product.id)")
            } else {
                try await service.add(productID: product.id, userID: userID)
                Log.confirmed("favourite added: \(product.id)")
            }
        } catch {
            Log.failed("favourite toggle \(product.id)", error)
            errorMessage = error.userMessage
        }
    }
}
