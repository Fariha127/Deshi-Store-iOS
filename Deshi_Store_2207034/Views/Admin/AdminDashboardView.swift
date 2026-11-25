import SwiftUI

/// The UI check below is only a convenience. Real protection comes from Firestore
/// security rules, which reject product writes from non-admin accounts.
struct AdminDashboardView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var productsVM: ProductsViewModel
    @StateObject private var admin = AdminViewModel()
    @State private var remoteURL = ""
    @State private var productToDelete: Product?

    var body: some View {
        Group {
            if auth.isAdmin { content }
            else {
                EmptyStateView(icon: "lock.fill", title: "Admins only",
                               message: "Your account doesn't have permission to manage products.")
            }
        }
        .navigationTitle("Admin Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        List {
            if let message = admin.errorMessage { Section { ErrorBanner(message: message) }.listRowBackground(Color.clear) }
            if let message = admin.infoMessage { Section { InfoBanner(message: message) }.listRowBackground(Color.clear) }

            Section("Import products (JSON)") {
                Button {
                    Task { await admin.importBundled() }
                } label: {
                    Label("Import sample Bangladeshi products", systemImage: "square.and.arrow.down")
                }
                TextField("https://…/products.json", text: $remoteURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    Task { await admin.importRemote(urlString: remoteURL) }
                } label: {
                    Label("Import from URL", systemImage: "network")
                }
                .disabled(remoteURL.trimmed.isEmpty)
                if admin.isWorking { ProgressView() }
            }
            .disabled(admin.isWorking)

            Section("Products (\(productsVM.products.count))") {
                if productsVM.products.isEmpty {
                    Text("No products yet. Import samples or tap + to add one.").foregroundStyle(.secondary)
                }
                ForEach(productsVM.products) { product in
                    NavigationLink {
                        ProductFormView(mode: .edit(product))
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.name).font(.subheadline.weight(.semibold))
                            Text("\(product.brand) · \(product.price.takaString)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) { productToDelete = product } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink { ProductFormView(mode: .add) } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add product")
            }
        }
        .confirmationDialog("Delete this product?",
                            isPresented: Binding(get: { productToDelete != nil }, set: { if !$0 { productToDelete = nil } }),
                            titleVisibility: .visible, presenting: productToDelete) { product in
            Button("Delete \(product.name)", role: .destructive) { Task { await admin.delete(product) } }
        }
    }
}
