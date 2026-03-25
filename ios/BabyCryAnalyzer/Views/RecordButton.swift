import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let isAnalyzing: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            ZStack {
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.08))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)

                    Circle()
                        .fill(Color.red.opacity(0.05))
                        .frame(width: 150, height: 150)
                        .scaleEffect(pulseScale * 0.95)
                }

                Circle()
                    .fill(
                        isRecording
                            ? AnyShapeStyle(Color.red.opacity(0.9))
                            : AnyShapeStyle(Color(.label))
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: isRecording ? .red.opacity(0.3) : .black.opacity(0.08), radius: isRecording ? 20 : 10, y: isRecording ? 0 : 4)

                if isAnalyzing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(isRecording ? .white : Color(.systemBackground))
                        .contentTransition(.symbolEffect(.replace))
                }
            }
        }
        .disabled(isAnalyzing)
        .sensoryFeedback(.impact(weight: .medium), trigger: isRecording)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.2
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    pulseScale = 1.0
                }
            }
        }
    }
}
