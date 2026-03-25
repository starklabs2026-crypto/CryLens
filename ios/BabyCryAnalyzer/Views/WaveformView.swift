import SwiftUI

struct WaveformView: View {
    let levels: [Float]
    let isActive: Bool

    private let barCount = 48

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                let level = index < levels.count ? CGFloat(levels[index]) : 0.0
                let height: CGFloat = isActive ? max(3, level * 44) : 3

                Capsule()
                    .fill(barColor(for: index, level: Float(level)))
                    .frame(width: 3, height: height)
                    .animation(
                        .spring(response: 0.15, dampingFraction: 0.7),
                        value: height
                    )
            }
        }
        .frame(height: 48)
    }

    private func barColor(for index: Int, level: Float) -> Color {
        if !isActive { return Color(.quaternaryLabel) }
        let centerDistance = abs(Double(index) - Double(barCount) / 2.0) / (Double(barCount) / 2.0)
        let opacity = 0.3 + Double(level) * 0.5 + (1.0 - centerDistance) * 0.2
        return Color(.label).opacity(opacity)
    }
}
