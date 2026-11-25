import SwiftUI

enum ProductFormMode {
    case add
    case edit(Product)
}

/// Used for both "Add Product" and "Edit Product".
struct ProductFormView: View {
    let mode: ProductFormMode
    @Environment(\.dismiss) private var dismiss
    @StateObject private var admin = AdminViewModel()

    @State private var name = ""
    @State private var brand = ""
    @State private var category = ProductCategory.foodSnacks.rawValue
    @State private var priceText = ""
    @State private var country = "Bangladesh"
    @State private var details = ""
    @State private var imageURL = ""

    private var existingID: String? {
        if case .edit(let product) = mode { return product.id }
        return nil
    }

    init(mode: ProductFormMode) {
        self.mode = mode
        if case .edit(let p) = mode {
            _name = State(initialValue: p.name)
            _brand = State(initialValue: p.brand)
            _category = State(initialValue: p.category)
            _priceText = State(initialValue: p.price.formatted(.number.locale(Locale(identifier: "en_US")).grouping(.never).precision(.fractionLength(0...2))))
            _country = State(initialValue: p.countryOfOrigin)
            _details = State(initialValue: p.description)
            _imageURL = State(initialValue: p.imageURL)
        }
    }

    private var categoryOptions: [String] {
        var options = ProductCategory.allCases.map(\.rawValue)
        if !options.contains(category) { options.append(category) }
        return options
    }

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Product name", text: $name)
                TextField("Brand", text: $brand)
                Picker("Category", selection: $category) {
                    ForEach(categoryOptions, id: \.self) { Text($0).tag($0) }
                }
                HStack {
                    Text("৳")
                    TextField("Price (BDT)", text: $priceText).keyboardType(.decimalPad)
                }
                TextField("Country of origin", text: $country)
            }

            Section("Description") {
                TextEditor(text: $details).frame(minHeight: 110)
            }

            Section {
                ProductImageView(urlString: imageURL)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                TextField("Paste an https image URL", text: $imageURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Image")
            } footer: {
                Text("Use a direct link to an image (ends in .jpg or .png).")
            }

            if let message = admin.errorMessage {
                Section { ErrorBanner(message: message) }.listRowBackground(Color.clear)
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    if admin.isWorking { ProgressView().tint(.white) }
                    else { Text(existingID == nil ? "Add Product" : "Save Changes") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(admin.isWorking)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle(existingID == nil ? "Add Product" : "Edit Product")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() async {
        let price = Double(priceText.replacingOccurrences(of: ",", with: "").trimmed) ?? 0
        let draft = ProductDraft(name: name, brand: brand, category: category, price: price,
                                 countryOfOrigin: country, description: details, imageURL: imageURL)
        if await admin.save(draft: draft, existingID: existingID) {
            dismiss()
        }
    }
}
