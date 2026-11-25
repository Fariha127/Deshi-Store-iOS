import Foundation

enum ProductCategory: String, CaseIterable, Identifiable, Hashable {
    case foodSnacks = "Food & Snacks"
    case beverages = "Beverages"
    case groceries = "Spices & Groceries"
    case dairy = "Dairy Products"
    case personalCare = "Personal Care"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .foodSnacks: return "fork.knife"
        case .beverages: return "cup.and.saucer.fill"
        case .groceries: return "basket.fill"
        case .dairy: return "drop.circle.fill"
        case .personalCare: return "sparkles"
        }
    }
}
