import Foundation

@MainActor
final class AdminViewModel: ObservableObject {
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let products = ProductService()
    private let seed = SeedService()

    /// Creates (existingID == nil) or updates a product.
    func save(draft: ProductDraft, existingID: String?) async -> Bool {
        errorMessage = nil
        if let problem = draft.validationError { errorMessage = problem; return false }
        isWorking = true
        defer { isWorking = false }
        do {
            if let existingID {
                try await products.update(id: existingID, with: draft)
                Log.confirmed("product updated: \(existingID)")
            } else {
                try await products.add(draft)
                Log.confirmed("product added: \(draft.name)")
            }
            return true
        } catch {
            Log.failed("save product \(draft.name)", error)
            errorMessage = error.userMessage
            return false
        }
    }

    func delete(_ product: Product) async {
        errorMessage = nil
        do {
            try await products.delete(id: product.id)
            Log.confirmed("product deleted: \(product.id)")
        } catch {
            Log.failed("delete product \(product.id)", error)
            errorMessage = error.userMessage
        }
    }

    func importBundled() async {
        await runImport { try self.seed.loadBundled() }
    }

    func importRemote(urlString: String) async {
        await runImport { try await self.seed.loadRemote(from: urlString) }
    }

    private func runImport(_ load: () async throws -> [ProductDraft]) async {
        errorMessage = nil
        infoMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            let drafts = try await load()
            let created = try await products.importMissing(drafts)
            let skipped = drafts.count - created
            Log.confirmed("imported \(created) products (\(skipped) already existed)")
            infoMessage = "Imported \(created) new product\(created == 1 ? "" : "s")" +
                (skipped > 0 ? " (\(skipped) already existed)." : ".")
        } catch {
            Log.failed("import products", error)
            errorMessage = (error as? DecodingError) != nil
                ? "The JSON format is invalid. Expected an array of products."
                : error.userMessage
        }
    }
}
