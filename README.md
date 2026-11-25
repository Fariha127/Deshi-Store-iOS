# Deshi Store (iOS)

A SwiftUI + Firebase app for discovering and reviewing Bangladeshi products.

## Features
- Browse products by category, in a grid with images, names and prices in BDT (৳)
- Search by name or brand, with empty states
- Favourites saved per user in Firestore
- Product details: brand, category, price, country of origin, description
- Star ratings and reviews, with average rating and review count
- Admin-only product management (add, edit, delete, JSON import)

## Tech
Swift, SwiftUI, MVVM, Firebase Authentication, Cloud Firestore, URLSession + Codable (JSON import), AsyncImage.
Target: iOS 16+. Firebase iOS SDK 9.6.0 (FirebaseAuth and FirebaseFirestore only).

## Project structure
- Models: Product, AppUser, Review, Favourite, ProductCategory
- Services: Auth, Product, Favourite, Review, Seed (JSON/REST)
- ViewModels: Auth, Products, Favourites, Reviews, Admin
- Views: Auth, Home, Search, Product, Reviews, Favourites, Profile, Admin, Components
- Resources: products_seed.json (sample products)
- firestore.rules: Firestore security rules

## Setup
1. Create a Firebase project and add an iOS app with bundle ID uts.Deshi-Store-2207034.
2. Download GoogleService-Info.plist, name it exactly that, and add it to the app target (it is not stored in this repo).
3. Enable Email/Password sign-in; create Firestore; publish firestore.rules.
4. Build and run, register an account, then set role to admin on your users document in the Firestore console.
5. In the app: Profile > Admin Dashboard > Import sample Bangladeshi products.

## Admin security
Admin status is the role field on users/{uid}. The Firestore rules block users from changing their own role and allow product writes only for admins; hiding admin buttons in the UI is not the protection.

## Note: Xcode 14.1 beta
This project was built with Xcode 14.1 beta. FirebaseAuth 9.6.0 fails to compile there (GameKit / GameController module errors from the Game Center sign-in files). The workaround was a local copy of the firebase-ios-sdk 9.6.0 checkout with the Game Center code removed, added to Xcode as a local package. That patched copy is not in this repo. With a stable Xcode (14.2 or later) you can use the normal Firebase package and skip this entirely.

## Known limitations
- Rating averages are updated from the client in a transaction; a Cloud Function would be more robust.
- Deleting a product does not delete its reviews or users' favourites.
- Sample products have no images; add an https image URL in the admin edit screen.
