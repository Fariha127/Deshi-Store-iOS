import Foundation

enum UserRole: String { case user, admin }

struct AppUser: Identifiable, Equatable {
    let id: String
    var name: String
    var email: String
    var role: UserRole

    var isAdmin: Bool { role == .admin }

    init(id: String, name: String, email: String, role: UserRole = .user) {
        self.id = id; self.name = name; self.email = email; self.role = role
    }

    init?(id: String, data: [String: Any]) {
        guard let name = data["name"] as? String, let email = data["email"] as? String else { return nil }
        self.init(id: id, name: name, email: email,
                  role: UserRole(rawValue: data["role"] as? String ?? "user") ?? .user)
    }

    var data: [String: Any] {
        ["userId": id, "name": name, "email": email, "role": role.rawValue]
    }
}
