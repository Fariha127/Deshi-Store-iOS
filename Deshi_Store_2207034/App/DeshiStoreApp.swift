import SwiftUI
import FirebaseCore

@main
struct DeshiStoreApp: App {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var products = ProductsViewModel()
    @StateObject private var favourites = FavouritesViewModel()

    init() { FirebaseApp.configure() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(products)
                .environmentObject(favourites)
                .tint(Theme.green)
                .preferredColorScheme(.light)
        }
    }
}
