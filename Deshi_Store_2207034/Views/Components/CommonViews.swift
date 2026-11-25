import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Theme.green.opacity(0.7))
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

struct ErrorBanner: View {
    let message: String
    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(.red)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct InfoBanner: View {
    let message: String
    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(Theme.green)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.greenSoft, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct ProductImageView: View {
    let urlString: String

    var body: some View {
        Theme.greenSoft
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let url = URL(string: urlString), !urlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        case .failure: fallback
                        default: ProgressView()
                        }
                    }
                } else {
                    fallback
                }
            }
            .clipped()
    }

    private var fallback: some View {
        Image(systemName: "photo")
            .font(.system(size: 34))
            .foregroundStyle(Theme.green.opacity(0.5))
    }
}

struct StarRatingView: View {
    let rating: Double
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: symbol(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(.yellow)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Rated \(rating.formatted(.number.precision(.fractionLength(1)))) out of 5")
    }

    private func symbol(for index: Int) -> String {
        if rating >= Double(index) { return "star.fill" }
        if rating >= Double(index) - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

struct StarRatingInput: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { index in
                Button {
                    rating = index
                } label: {
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .font(.title)
                        .foregroundStyle(.yellow)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(index) star\(index == 1 ? "" : "s")")
            }
        }
    }
}

struct FavouriteButton: View {
    let product: Product
    @EnvironmentObject private var favourites: FavouritesViewModel

    var body: some View {
        let isFav = favourites.isFavourite(product.id)
        Button {
            Task { await favourites.toggle(product) }
        } label: {
            Image(systemName: isFav ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isFav ? Color.red : Color.secondary)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFav ? "Remove from favourites" : "Add to favourites")
    }
}

struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProductImageView(urlString: product.imageURL)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(product.brand)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            HStack {
                Text(product.price.takaString)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.green)
                Spacer()
                if product.reviewCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                        Text(product.averageRating.formatted(.number.precision(.fractionLength(1))))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .cardStyle()
    }
}

/// Two-column grid of tappable product cards with a favourite button overlay.
struct ProductGrid: View {
    let products: [Product]
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(products) { product in
                ZStack(alignment: .topTrailing) {
                    NavigationLink(value: product) {
                        ProductCard(product: product)
                    }
                    .buttonStyle(.plain)
                    FavouriteButton(product: product)
                        .padding(16)
                }
            }
        }
    }
}

extension View {
    /// Registers navigation to product details for the surrounding NavigationStack.
    func productDestination() -> some View {
        navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
    }
}
