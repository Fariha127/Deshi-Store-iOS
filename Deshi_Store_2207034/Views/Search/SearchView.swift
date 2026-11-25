import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var productsVM: ProductsViewModel
    @State private var query = ""

    var body: some View {
        NavigationStack {
            let results = productsVM.search(query)
            ScrollView {
                if query.trimmed.isEmpty {
                    EmptyStateView(icon: "magnifyingglass", title: "Search Deshi Store",
                                   message: "Find products by name or brand, e.g. “Radhuni” or “Jamdani”.")
                } else if results.isEmpty {
                    EmptyStateView(icon: "questionmark.folder", title: "No products found",
                                   message: "We couldn't find anything for “\(query.trimmed)”. Try a different name or brand.")
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ProductGrid(products: results)
                    }
                    .padding()
                }
            }
            .background(Theme.background)
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search by name or brand")
            .productDestination()
        }
    }
}
