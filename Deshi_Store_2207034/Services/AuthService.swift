import Foundation
import FirebaseAuth
import FirebaseFirestore

struct AuthService {
    private let db = Firestore.firestore()

    func register(name: String, email: String, password: String) async throws -> AppUser {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        // Role is always "user" on sign-up; Firestore rules reject anything else.
        let user = AppUser(id: result.user.uid, name: name, email: email, role: .user)
        try await db.collection("users").document(user.id).setData(user.data)
        return user
    }

    func login(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func logout() throws { try Auth.auth().signOut() }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    /// Loads the Firestore profile (name + role). Creates a default one if missing.
    func profile(for firebaseUser: User) async throws -> AppUser {
        let ref = db.collection("users").document(firebaseUser.uid)
        let snapshot = try await ref.getDocument()
        if let data = snapshot.data(), let user = AppUser(id: firebaseUser.uid, data: data) {
            return user
        }
        let email = firebaseUser.email ?? ""
        let fallbackName = firebaseUser.displayName ?? email.components(separatedBy: "@").first ?? "User"
        let user = AppUser(id: firebaseUser.uid, name: fallbackName, email: email, role: .user)
        try await ref.setData(user.data)
        return user
    }
}
