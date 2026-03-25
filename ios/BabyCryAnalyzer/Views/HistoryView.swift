import SwiftUI

struct HistoryView: View {
    @Environment(CryHistoryStore.self) private var historyStore
    @State private var showClearConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if historyStore.analyses.isEmpty {
                    ContentUnavailableView(
                        "No Analyses Yet",
                        systemImage: "waveform.path",
                        description: Text("Start recording your baby's crying to see analysis history here.")
                    )
                } else {
                    List {
                        ForEach(historyStore.groupedByDate, id: \.0) { section in
                            Section {
                                ForEach(section.1) { analysis in
                                    HistoryRow(analysis: analysis)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                }
                            } header: {
                                Text(section.0.uppercased())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .tracking(1)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !historyStore.analyses.isEmpty {
                        Button("Clear") {
                            showClearConfirmation = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .confirmationDialog("Clear History", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) {
                    withAnimation {
                        historyStore.clearAll()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all cry analysis records.")
            }
        }
    }
}

struct HistoryRow: View {
    let analysis: CryAnalysis
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(reasonColor.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: analysis.reason.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(reasonColor)
                            .symbolRenderingMode(.hierarchical)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(analysis.reason.rawValue)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)

                        Text(analysis.date, style: .time)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Text("\(Int(analysis.confidence * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(reasonColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(reasonColor.opacity(0.1))
                        .clipShape(Capsule())

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.quaternary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 16) {
                        Label(formattedDuration, systemImage: "clock")
                        Label(String(format: "%.0f dB", analysis.averageDecibels), systemImage: "speaker.wave.2")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                    Text(analysis.tip)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
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
