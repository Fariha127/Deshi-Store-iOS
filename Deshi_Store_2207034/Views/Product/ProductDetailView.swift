import SwiftUI

struct ProductDetailView: View {
    private let initialProduct: Product
    @EnvironmentObject private var productsVM: ProductsViewModel
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var reviews: ReviewsViewModel
    @State private var showWriteReview = false

    init(product: Product) {
        self.initialProduct = product
        _reviews = StateObject(wrappedValue: ReviewsViewModel(productID: product.id))
    }

    /// Always show the live Firestore version so rating changes appear instantly.
    private var product: Product {
        productsVM.products.first { $0.id == initialProduct.id } ?? initialProduct
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ProductImageView(urlString: product.imageURL)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                VStack(alignment: .leading, spacing: 6) {
                    Text(product.brand.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.green)
                    Text(product.name).font(.title2.bold())
                    Text(product.price.takaString)
                        .font(.title.bold())
                        .foregroundStyle(Theme.green)
                    NavigationLink {
                        ReviewsView(product: product, viewModel: reviews)
                    } label: {
                        ratingSummary
                    }
                    .buttonStyle(.plain)
                }
                RecommendButton(product: product)

                infoCard

                VStack(alignment: .leading, spacing: 8) {
                    Text("Description").font(.headline)
                    Text(product.description).foregroundStyle(.secondary)
                }

                reviewsSection
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { FavouriteButton(product: product) } }
        .task { reviews.start() }
        .sheet(isPresented: $showWriteReview) {
            WriteReviewView(product: product, viewModel: reviews,
                            existing: reviews.myReview(userID: auth.currentUser?.id))
        }
    }

    private var ratingSummary: some View {
        HStack(spacing: 8) {
            StarRatingView(rating: product.averageRating, size: 15)
            if product.reviewCount > 0 {
                Text("\(product.averageRating.formatted(.number.precision(.fractionLength(1)))) · \(product.reviewCount) review\(product.reviewCount == 1 ? "" : "s")")
            } else {
                Text("No reviews yet")
            }
            Image(systemName: "chevron.right").font(.caption)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow("Brand", product.brand)
            Divider()
            infoRow("Category", product.category)
            Divider()
            infoRow("Country of origin", product.countryOfOrigin)
            Divider()
            infoRow("Price", product.price.takaString)
        }
        .padding(.horizontal, 14)
        .cardStyle()
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 12)
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reviews").font(.headline)
                Spacer()
                if reviews.reviews.count > 3 {
                    NavigationLink("See all") { ReviewsView(product: product, viewModel: reviews) }
                        .font(.subheadline)
                }
            }

            if reviews.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if reviews.reviews.isEmpty {
                EmptyStateView(icon: "text.bubble", title: "No reviews yet",
                               message: "Be the first to share what you think.")
            } else {
                ForEach(reviews.reviews.prefix(3)) { ReviewRow(review: $0) }
            }

            Button {
                showWriteReview = true
            } label: {
                Label(reviews.myReview(userID: auth.currentUser?.id) == nil ? "Write a Review" : "Edit Your Review",
                      systemImage: "square.and.pencil")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}
