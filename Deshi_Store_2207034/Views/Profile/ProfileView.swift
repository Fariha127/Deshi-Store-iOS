import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var favourites: FavouritesViewModel
    @State private var confirmLogout = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Text((auth.currentUser?.name ?? "?").initials)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Theme.green, in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(auth.currentUser?.name ?? "").font(.headline)
                            Text(auth.currentUser?.email ?? "").font(.subheadline).foregroundStyle(.secondary)
                            if auth.isAdmin {
                                Text("ADMIN")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Theme.green)
                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                    .background(Theme.greenSoft, in: Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Account") {
                    LabeledContent("Saved favourites", value: "\(favourites.favourites.count)")
                    Button("Send password reset email") { Task { await auth.sendPasswordReset() } }
                }

                if auth.isAdmin {
                    Section("Administration") {
                        NavigationLink {
                            AdminDashboardView()
                        } label: {
                            Label("Admin Dashboard", systemImage: "slider.horizontal.3")
                        }
                    }
                }

                if let message = auth.infoMessage { Section { InfoBanner(message: message) }.listRowBackground(Color.clear) }
                if let message = auth.errorMessage { Section { ErrorBanner(message: message) }.listRowBackground(Color.clear) }

                Section {
                    Button("Log Out", role: .destructive) { confirmLogout = true }
                }
            }
            .navigationTitle("Profile")
            .onAppear { auth.infoMessage = nil; auth.errorMessage = nil }
            .confirmationDialog("Log out of Deshi Store?", isPresented: $confirmLogout, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) { auth.logout() }
            }
        }
    }
}
