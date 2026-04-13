import SwiftUI

struct WaveformView: View {
    let audioLevel: Float

    @State private var offsets: [CGFloat] = Array(repeating: 0, count: 20)
    private let barCount = 20
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: barHeight(for: i))
                    .animation(.easeInOut(duration: 0.1), value: offsets[i])
            }
        }
        .frame(height: 80)
        .onReceive(timer) { _ in
            for i in 0..<barCount {
                offsets[i] = CGFloat.random(in: -10...10)
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base = CGFloat(audioLevel) * 60 + 10
        return max(4, base + offsets[index])
    }
}
