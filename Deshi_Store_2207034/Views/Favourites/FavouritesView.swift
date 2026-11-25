import SwiftUI

struct FavouritesView: View {
    @EnvironmentObject private var productsVM: ProductsViewModel
    @EnvironmentObject private var favourites: FavouritesViewModel

    var body: some View {
        NavigationStack {
            let lookup = Dictionary(uniqueKeysWithValues: productsVM.products.map { ($0.id, $0) })
            let items = favourites.orderedIDs.compactMap { lookup[$0] }

            ScrollView {
                if let message = favourites.errorMessage {
                    ErrorBanner(message: message).padding()
                }
                if items.isEmpty {
                    EmptyStateView(icon: "heart", title: "No favourites yet",
                                   message: "Tap the heart on any product to save it here.")
                } else {
                    ProductGrid(products: items).padding()
                }
            }
            .background(Theme.background)
            .navigationTitle("Favourites")
            .productDestination()
        }
    }
}
