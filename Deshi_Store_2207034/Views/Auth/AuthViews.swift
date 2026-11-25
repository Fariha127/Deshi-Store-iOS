import SwiftUI

struct AuthField: View {
    let title: String
    @Binding var text: String
    var secure = false
    var keyboard: UIKeyboardType = .default

    var body: some View {
        Group {
            if secure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                    .autocorrectionDisabled(keyboard == .emailAddress)
            }
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.25)))
    }
}

struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .frame(width: 96, height: 96)
                    .background(Theme.green, in: Circle())
                    .padding(.top, 40)
                Text("Welcome to Deshi Store")
                    .font(.title2.bold())
                Text("Discover and review Bangladeshi products")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                AuthField(title: "Email", text: $email, keyboard: .emailAddress)
                AuthField(title: "Password", text: $password, secure: true)

                if let message = auth.errorMessage { ErrorBanner(message: message) }

                Button {
                    Task { await auth.login(email: email, password: password) }
                } label: {
                    if auth.isWorking { ProgressView().tint(.white) } else { Text("Log In") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(auth.isWorking)

                NavigationLink("New here? Create an account") { RegisterView() }
                    .font(.subheadline.weight(.semibold))
            }
            .padding(24)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear { auth.errorMessage = nil }
    }
}

struct RegisterView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Create your account").font(.title2.bold()).padding(.top, 16)
                AuthField(title: "Full name", text: $name)
                AuthField(title: "Email", text: $email, keyboard: .emailAddress)
                AuthField(title: "Password (min. 6 characters)", text: $password, secure: true)
                AuthField(title: "Confirm password", text: $confirmation, secure: true)

                if let message = auth.errorMessage { ErrorBanner(message: message) }

                Button {
                    Task { await auth.register(name: name, email: email, password: password, confirmation: confirmation) }
                } label: {
                    if auth.isWorking { ProgressView().tint(.white) } else { Text("Sign Up") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(auth.isWorking)
            }
            .padding(24)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { auth.errorMessage = nil }
    }
}
