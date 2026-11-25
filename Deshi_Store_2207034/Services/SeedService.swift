import Foundation

enum SeedError: LocalizedError {
    case missingFile, invalidURL, badStatus(Int), empty, tooMany, invalidItem(String)

    var errorDescription: String? {
        switch self {
        case .missingFile: return "products_seed.json was not found in the app bundle."
        case .invalidURL: return "Enter a valid https URL."
        case .badStatus(let code): return "The server responded with status \(code)."
        case .empty: return "The JSON file contains no products."
        case .tooMany: return "Import is limited to 400 products at a time."
        case .invalidItem(let message): return message
        }
    }
}

/// Loads product data from the bundled JSON file or a remote REST endpoint,
/// parsing it with Codable.
struct SeedService {
    func loadBundled() throws -> [ProductDraft] {
        guard let url = Bundle.main.url(forResource: "products_seed", withExtension: "json") else {
            throw SeedError.missingFile
        }
        return try validated(try JSONDecoder().decode([ProductDraft].self, from: Data(contentsOf: url)))
    }

    func loadRemote(from urlString: String) async throws -> [ProductDraft] {
        guard let url = URL(string: urlString.trimmed), url.scheme == "https" else { throw SeedError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SeedError.badStatus(http.statusCode)
        }
        return try validated(try JSONDecoder().decode([ProductDraft].self, from: data))
    }

    private func validated(_ drafts: [ProductDraft]) throws -> [ProductDraft] {
        guard !drafts.isEmpty else { throw SeedError.empty }
        guard drafts.count <= 400 else { throw SeedError.tooMany }
        for draft in drafts {
            if let problem = draft.validationError {
                throw SeedError.invalidItem("\"\(draft.name)\": \(problem)")
            }
        }
        return drafts
    }
}
