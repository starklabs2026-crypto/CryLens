import SwiftUI

struct CryLensLogo: View {
    var size: CGFloat = 88

    private let coral = Color(hex: "FF6B6B")
    private let sunset = Color(hex: "FF8E53")
    private let cream = Color(hex: "FFF6F2")
    private let ink = Color(hex: "2B1F1B")

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [coral, sunset],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: size * 0.018)

            Circle()
                .fill(cream.opacity(0.22))
                .frame(width: size * 0.62, height: size * 0.62)
                .blur(radius: size * 0.01)

            HStack(spacing: size * 0.036) {
                bar(height: 0.16)
                bar(height: 0.28)
                bar(height: 0.44)
                bar(height: 0.60)
                bar(height: 0.44)
                bar(height: 0.28)
                bar(height: 0.16)
            }

            Circle()
                .fill(ink.opacity(0.08))
                .frame(width: size * 0.14, height: size * 0.14)
                .offset(x: size * 0.21, y: size * 0.21)
        }
        .frame(width: size, height: size)
        .shadow(color: coral.opacity(0.18), radius: size * 0.1, y: size * 0.06)
        .accessibilityHidden(true)
    }

    private func bar(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.03, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.white, cream],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.05, height: size * height)
            .shadow(color: .white.opacity(0.12), radius: size * 0.012, y: 0)
    }
}
