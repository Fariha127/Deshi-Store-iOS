import Foundation

@MainActor
final class ProductsViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service = ProductService()
    private let bag = ListenerBag()

    func start() {
        guard !bag.isActive else { return }
        isLoading = true
        errorMessage = nil
        bag.set(service.listen { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let items):
                    self.products = items
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = error.userMessage
                }
            }
        })
    }

    func stop() {
        bag.set(nil)
        products = []
    }

    func reload() { bag.set(nil); start() }

    func products(in category: ProductCategory) -> [Product] {
        products.filter { $0.category == category.rawValue }
    }

    /// Case-insensitive search on product name or brand.
    func search(_ query: String) -> [Product] {
        let q = query.trimmed
        guard !q.isEmpty else { return [] }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(q) || $0.brand.localizedCaseInsensitiveContains(q)
        }
    }
}
