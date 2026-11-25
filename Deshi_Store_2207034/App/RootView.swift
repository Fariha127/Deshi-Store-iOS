import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var products: ProductsViewModel
    @EnvironmentObject private var favourites: FavouritesViewModel
    @State private var splashFinished = false

    var body: some View {
        Group {
            if !splashFinished || auth.state == .checking {
                SplashView()
            } else if auth.state == .signedIn {
                MainTabView()
            } else {
                NavigationStack { LoginView() }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: auth.state)
        .task {
            auth.start()
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            splashFinished = true
        }
        .onChange(of: auth.currentUser?.id) { newID in
            if let newID {
                products.start()
                favourites.start(userID: newID)
            } else {
                products.stop()
                favourites.stop()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var favourites: FavouritesViewModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            FavouritesView()
                .tabItem { Label("Favourites", systemImage: "heart.fill") }
                .badge(favourites.favourites.count)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { favourites.errorMessage != nil },
                                    set: { if !$0 { favourites.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(favourites.errorMessage ?? "")
        }
    }
}
