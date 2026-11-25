import SwiftUI

enum Theme {
    /// Bangladesh flag green (#006A4E)
    static let green = Color(red: 0.0, green: 0.416, blue: 0.306)
    static let greenSoft = Color(red: 0.0, green: 0.416, blue: 0.306).opacity(0.10)
    static let background = Color(red: 0.97, green: 0.98, blue: 0.97)
    static let card = Color.white
    static let corner: CGFloat = 16
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.green.opacity(isEnabled ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

extension View {
    func cardStyle() -> some View {
        self.background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.corner))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}
