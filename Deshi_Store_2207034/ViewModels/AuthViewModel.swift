import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    enum State { case checking, signedOut, signedIn }

    @Published private(set) var state: State = .checking
    @Published private(set) var currentUser: AppUser?
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    var isAdmin: Bool { currentUser?.isAdmin ?? false }

    private let service = AuthService()
    private var handle: AuthStateDidChangeListenerHandle?
    private var isRegistering = false

    func start() {
        guard handle == nil else { return }
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in await self?.authChanged(firebaseUser) }
        }
    }

    private func authChanged(_ firebaseUser: User?) async {
        if isRegistering { return }   // register() sets the profile itself
        guard let firebaseUser else {
            currentUser = nil
            state = .signedOut
            return
        }
        do {
            currentUser = try await service.profile(for: firebaseUser)
            state = .signedIn
        } catch {
            errorMessage = error.userMessage
            try? service.logout()
            currentUser = nil
            state = .signedOut
        }
    }

    func login(email: String, password: String) async {
        errorMessage = nil
        guard email.trimmed.isValidEmail else { errorMessage = "Enter a valid email address."; return }
        guard !password.isEmpty else { errorMessage = "Enter your password."; return }
        isWorking = true
        defer { isWorking = false }
        do { try await service.login(email: email.trimmed, password: password) }
        catch { errorMessage = error.userMessage }
    }

    func register(name: String, email: String, password: String, confirmation: String) async {
        errorMessage = nil
        guard name.trimmed.count >= 2 else { errorMessage = "Enter your name."; return }
        guard email.trimmed.isValidEmail else { errorMessage = "Enter a valid email address."; return }
        guard password.count >= 6 else { errorMessage = "Password must be at least 6 characters."; return }
        guard password == confirmation else { errorMessage = "Passwords do not match."; return }
        isWorking = true
        isRegistering = true
        defer { isWorking = false; isRegistering = false }
        do {
            currentUser = try await service.register(name: name.trimmed, email: email.trimmed, password: password)
            Log.confirmed("users/\(currentUser?.id ?? "?") profile created")
            state = .signedIn
        } catch {
            Log.failed("register", error)
            errorMessage = error.userMessage
        }
    }

    func logout() {
        try? service.logout()
        errorMessage = nil
    }

    func sendPasswordReset() async {
        guard let email = currentUser?.email else { return }
        do {
            try await service.sendPasswordReset(email: email)
            infoMessage = "Password reset email sent to \(email)."
        } catch {
            errorMessage = error.userMessage
        }
    }
}
