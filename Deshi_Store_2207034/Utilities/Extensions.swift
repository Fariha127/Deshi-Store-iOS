import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

extension Double {
    /// Bangladeshi Taka formatting, e.g. ৳8,500 or ৳45.50
    var takaString: String {
        "৳" + formatted(.number.locale(Locale(identifier: "en_US")).precision(.fractionLength(0...2)))
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// "Pran Frooto Mango" -> "pran-frooto-mango" (stable seed document IDs)
    var slug: String {
        lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    var initials: String {
        let letters = split(separator: " ").prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
}

extension UIImage {
    /// Downscales and compresses an image before uploading to Firebase Storage.
    func resizedJPEG(maxDimension: CGFloat = 1200, quality: CGFloat = 0.75) -> Data? {
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let image = renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
        return image.jpegData(compressionQuality: quality)
    }
}

extension Error {
    /// Human-friendly message for Auth / Firestore / network errors.
    /// Uses raw error codes so it compiles on every Firebase SDK version (9.x and 10+).
    var userMessage: String {
        let ns = self as NSError
        if ns.domain == AuthErrorDomain {
            switch ns.code {
            case 17009, 17004, 17011: return "Incorrect email or password."   // wrongPassword, invalidCredential, userNotFound
            case 17007: return "An account with this email already exists."   // emailAlreadyInUse
            case 17026: return "Password is too weak. Use at least 6 characters."
            case 17008: return "Enter a valid email address."
            case 17020: return "Network error. Check your connection and try again."
            case 17010: return "Too many attempts. Please try again later."
            default: break
            }
        }
        if ns.domain == FirestoreErrorDomain, ns.code == 7 {   // 7 = permission denied
            return "You don't have permission to do that. Check your Firestore rules."
        }
        if ns.domain == NSURLErrorDomain {
            return "Network problem. Check your connection and try again."
        }
        return localizedDescription
    }
}

/// Console logging so you can SEE whether the Firebase server accepted a write.
/// `await setData(...)` only returns after the SERVER confirms, unlike the instant local cache.
enum Log {
    static func confirmed(_ what: String) { print("✅ WRITE CONFIRMED BY SERVER: \(what)") }
    static func failed(_ what: String, _ error: Error) {
        let ns = error as NSError
        print("❌ WRITE FAILED: \(what) — \(error.localizedDescription) [\(ns.domain) \(ns.code)]")
    }
}

/// Removes a Firestore listener automatically when its owner (a ViewModel) is deallocated.
final class ListenerBag {
    private var registration: ListenerRegistration?
    var isActive: Bool { registration != nil }
    func set(_ new: ListenerRegistration?) {
        registration?.remove()
        registration = new
    }
    deinit { registration?.remove() }
}
