import SwiftUI
import FirebaseCore

@main
struct DeshiStoreApp: App {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var products = ProductsViewModel()
    @StateObject private var favourites = FavouritesViewModel()
    @StateObject private var recommendations = RecommendationsViewModel()

    init() { FirebaseApp.configure() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(products)
                .environmentObject(favourites)
                .environmentObject(recommendations)
                .tint(Theme.green)
                .preferredColorScheme(.light)
        }
    }
}
