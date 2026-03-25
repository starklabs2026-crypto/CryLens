import SwiftUI

struct AnalysisResultCard: View {
    let analysis: CryAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // MARK: Header
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(reasonColor.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: analysis.reason.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(reasonColor)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.reason.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        Label("\(Int(analysis.confidence * 100))%", systemImage: "chart.bar.fill")
                        Label(formattedDuration, systemImage: "clock")
                        if let urgency = analysis.urgency {
                            urgencyBadge(urgency)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }

                Spacer()
            }

            // MARK: Tip
            Text(analysis.tip)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: Detailed Analysis
            if let detail = analysis.detailedAnalysis, !detail.isEmpty {
                sectionBlock(title: "Analysis", systemImage: "waveform.and.magnifyingglass") {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // MARK: Recommendations
            if let recs = analysis.recommendations, !recs.isEmpty {
                sectionBlock(title: "What to Try", systemImage: "list.bullet.clipboard") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recs, id: \.self) { rec in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(reasonColor)
                                    .font(.subheadline)
                                    .padding(.top, 1)
                                Text(rec)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }

            // MARK: Voice Recognition
            if let transcript = analysis.transcript {
                sectionBlock(title: "Voice Recognition", systemImage: "mic.fill") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(transcript)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let language = analysis.transcriptLanguage, !language.isEmpty {
                            Text(language.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.quaternary.opacity(0.5), in: .capsule)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionBlock<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    @ViewBuilder
    private func urgencyBadge(_ urgency: CryUrgency) -> some View {
        Text(urgency.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(urgencyColor(urgency).opacity(0.15), in: Capsule())
            .foregroundStyle(urgencyColor(urgency))
    }

    private func urgencyColor(_ urgency: CryUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var formattedDuration: String {
        if analysis.durationSeconds < 60 {
            return "\(analysis.durationSeconds)s"
        }
        return "\(analysis.durationSeconds / 60)m \(analysis.durationSeconds % 60)s"
    }

    private var reasonColor: Color {
        switch analysis.reason {
        case .hungry: return .orange
        case .tired: return .indigo
        case .uncomfortable: return .teal
        case .needsAttention: return .pink
        case .pain: return .red
        case .gassy: return .mint
        case .overstimulated: return .purple
        case .unknown: return .gray
        }
    }
}
