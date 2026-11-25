import SwiftUI

struct ReviewRow: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(review.userName.initials)
                    .font(.caption.bold())
                    .foregroundStyle(Theme.green)
                    .frame(width: 36, height: 36)
                    .background(Theme.greenSoft, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userName).font(.subheadline.weight(.semibold))
                    Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StarRatingView(rating: Double(review.rating))
            }
            Text(review.comment).font(.subheadline)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct ReviewsView: View {
    let product: Product
    @ObservedObject var viewModel: ReviewsViewModel
    @EnvironmentObject private var auth: AuthViewModel
    @State private var showWriteReview = false
    @State private var confirmDelete = false

    private var myReview: Review? { viewModel.myReview(userID: auth.currentUser?.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                summary

                if let message = viewModel.errorMessage { ErrorBanner(message: message) }

                Button {
                    showWriteReview = true
                } label: {
                    Label(myReview == nil ? "Write a Review" : "Edit Your Review", systemImage: "square.and.pencil")
                }
                .buttonStyle(PrimaryButtonStyle())

                if viewModel.isLoading {
                    ProgressView().padding()
                } else if viewModel.reviews.isEmpty {
                    EmptyStateView(icon: "text.bubble", title: "No reviews yet",
                                   message: "Be the first to review \(product.name).")
                } else {
                    ForEach(viewModel.reviews) { review in
                        ReviewRow(review: review)
                            .contextMenu {
                                if review.userId == auth.currentUser?.id {
                                    Button(role: .destructive) { confirmDelete = true } label: {
                                        Label("Delete my review", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Ratings & Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.start() }
        .sheet(isPresented: $showWriteReview) {
            WriteReviewView(product: product, viewModel: viewModel, existing: myReview)
        }
        .confirmationDialog("Delete your review?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let id = auth.currentUser?.id { Task { await viewModel.deleteMyReview(userID: id) } }
            }
        }
    }

    private var summary: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(viewModel.averageRating.formatted(.number.precision(.fractionLength(1))))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                StarRatingView(rating: viewModel.averageRating, size: 14)
                Text("\(viewModel.reviews.count) review\(viewModel.reviews.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 6) {
                ForEach((1...5).reversed(), id: \.self) { stars in
                    HStack(spacing: 6) {
                        Text("\(stars)").font(.caption).frame(width: 10)
                        ProgressView(value: Double(viewModel.count(forStars: stars)),
                                     total: Double(max(viewModel.reviews.count, 1)))
                            .tint(.yellow)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

struct WriteReviewView: View {
    let product: Product
    @ObservedObject var viewModel: ReviewsViewModel
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int
    @State private var comment: String

    init(product: Product, viewModel: ReviewsViewModel, existing: Review?) {
        self.product = product
        self.viewModel = viewModel
        _rating = State(initialValue: existing?.rating ?? 0)
        _comment = State(initialValue: existing?.comment ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your rating") {
                    StarRatingInput(rating: $rating).padding(.vertical, 4)
                }
                Section {
                    TextEditor(text: $comment).frame(minHeight: 140)
                } header: {
                    Text("Your review")
                } footer: {
                    Text("\(comment.count)/500")
                }
                if let message = viewModel.errorMessage {
                    Section { ErrorBanner(message: message) }.listRowBackground(Color.clear)
                }
                Section {
                    Button {
                        guard let user = auth.currentUser else { return }
                        Task {
                            if await viewModel.submit(rating: rating, comment: comment, user: user) { dismiss() }
                        }
                    } label: {
                        if viewModel.isSubmitting { ProgressView().tint(.white) } else { Text("Submit Review") }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isSubmitting)
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(product.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear { viewModel.errorMessage = nil }
        }
    }
}
