import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.green.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                Text("Deshi Store")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("দেশি স্টোর")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
                ProgressView().tint(.white).padding(.top, 24)
            }
        }
    }
}
