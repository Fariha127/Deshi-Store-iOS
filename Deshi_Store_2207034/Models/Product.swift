import Foundation

struct Product: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var brand: String
    var category: String
    var price: Double
    var countryOfOrigin: String
    var description: String
    var imageURL: String
    var averageRating: Double
    var reviewCount: Int
    var recommendCount: Int
}

extension Product {
    /// Builds a Product from a Firestore document.
    init?(id: String, data: [String: Any]) {
        guard let name = data["name"] as? String,
              let price = (data["price"] as? NSNumber)?.doubleValue else { return nil }
        self.id = id
        self.name = name
        self.brand = data["brand"] as? String ?? ""
        self.category = data["category"] as? String ?? ""
        self.price = price
        self.countryOfOrigin = data["countryOfOrigin"] as? String ?? "Bangladesh"
        self.description = data["description"] as? String ?? ""
        self.imageURL = data["imageURL"] as? String ?? ""
        self.averageRating = (data["averageRating"] as? NSNumber)?.doubleValue ?? 0
        self.reviewCount = (data["reviewCount"] as? NSNumber)?.intValue ?? 0
        self.recommendCount = (data["recommendCount"] as? NSNumber)?.intValue ?? 0
    }
}

/// Editable product fields (no rating data). Used by the admin form and for JSON seed import.
struct ProductDraft: Codable {
    var name: String
    var brand: String
    var category: String
    var price: Double
    var countryOfOrigin: String
    var description: String
    var imageURL: String?

    init(name: String, brand: String, category: String, price: Double,
         countryOfOrigin: String, description: String, imageURL: String?) {
        self.name = name; self.brand = brand; self.category = category; self.price = price
        self.countryOfOrigin = countryOfOrigin; self.description = description; self.imageURL = imageURL
    }

    init(from product: Product) {
        self.init(name: product.name, brand: product.brand, category: product.category,
                  price: product.price, countryOfOrigin: product.countryOfOrigin,
                  description: product.description, imageURL: product.imageURL)
    }

    /// Stable document ID for seed imports so re-importing never creates duplicates.
    var slug: String { "\(brand)-\(name)".slug }

    var validationError: String? {
        if name.trimmed.count < 2 { return "Enter a product name." }
        if brand.trimmed.isEmpty { return "Enter a brand." }
        if !ProductCategory.allCases.contains(where: { $0.rawValue == category }) { return "Choose a category." }
        if price <= 0 { return "Enter a price greater than 0." }
        if price > 10_000_000 { return "Price is too large." }
        if countryOfOrigin.trimmed.isEmpty { return "Enter the country of origin." }
        if description.trimmed.count < 10 { return "Description must be at least 10 characters." }
        if let url = imageURL?.trimmed, !url.isEmpty {
            guard let parsed = URL(string: url), parsed.scheme == "https", parsed.host != nil else {
                return "Image URL must be a valid https link."
            }
        }
        return nil
    }

    /// Firestore payload. Pass `productID` only when creating a document (adds rating counters).
    func firestoreData(productID: String? = nil) -> [String: Any] {
        var data: [String: Any] = [
            "name": name.trimmed,
            "brand": brand.trimmed,
            "category": category,
            "price": price,
            "countryOfOrigin": countryOfOrigin.trimmed,
            "description": description.trimmed,
            "imageURL": imageURL?.trimmed ?? ""
        ]
        if let productID {
            data["productId"] = productID
            data["averageRating"] = 0.0
            data["reviewCount"] = 0
            data["recommendCount"] = 0
        }
        return data
    }
}
