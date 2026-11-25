import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var productsVM: ProductsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    categories
                    productsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .toolbar(.hidden, for: .navigationBar)
            .productDestination()
            .navigationDestination(for: ProductCategory.self) { CategoryView(category: $0) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello, \(auth.currentUser?.name.components(separatedBy: " ").first ?? "there") 👋")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Discover Bangladeshi products")
                .font(.title.bold())
        }
        .padding(.top, 12)
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categories").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ProductCategory.allCases) { category in
                        NavigationLink(value: category) {
                            VStack(spacing: 8) {
                                Image(systemName: category.icon)
                                    .font(.title3)
                                    .foregroundStyle(Theme.green)
                                    .frame(width: 52, height: 52)
                                    .background(Theme.greenSoft, in: Circle())
                                Text(category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 84)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Products").font(.headline)
            if productsVM.isLoading && productsVM.products.isEmpty {
                ProgressView("Loading products…").frame(maxWidth: .infinity).padding(40)
            } else if let message = productsVM.errorMessage, productsVM.products.isEmpty {
                EmptyStateView(icon: "wifi.exclamationmark", title: "Couldn't load products",
                               message: message, actionTitle: "Try Again") { productsVM.reload() }
            } else if productsVM.products.isEmpty {
                EmptyStateView(icon: "shippingbox", title: "No products yet",
                               message: auth.isAdmin
                               ? "Open Profile → Admin Dashboard to import or add products."
                               : "Products will appear here once an admin adds them.")
            } else {
                ProductGrid(products: productsVM.products)
            }
        }
    }
}

struct CategoryView: View {
    let category: ProductCategory
    @EnvironmentObject private var productsVM: ProductsViewModel

    var body: some View {
        let items = productsVM.products(in: category)
        ScrollView {
            if items.isEmpty {
                EmptyStateView(icon: category.icon, title: "Nothing here yet",
                               message: "No products in \(category.rawValue) so far.")
            } else {
                ProductGrid(products: items).padding()
            }
        }
        .background(Theme.background)
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
