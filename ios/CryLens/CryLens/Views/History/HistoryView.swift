import SwiftUI

struct HistoryView: View {
    @State private var analyses: [CryAnalysis] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading history…")
                } else if analyses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No analyses yet — record your first cry")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(groupedByDate, id: \.key) { section in
                            Section(header: Text(section.key)) {
                                ForEach(section.analyses) { analysis in
                                    NavigationLink(destination: CryDetailView(analysis: analysis)) {
                                        HistoryRowView(analysis: analysis)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await load() }
                }
            }
            .navigationTitle("History")
            .task { await load() }
        }
    }

    private var groupedByDate: [DateGroup] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let iso = ISO8601DateFormatter()
        var groups: [String: [CryAnalysis]] = [:]

        for a in analyses {
            let date = iso.date(from: a.createdAt) ?? Date()
            let key = formatter.string(from: date)
            groups[key, default: []].append(a)
        }

        return groups
            .map { DateGroup(key: $0.key, analyses: $0.value) }
            .sorted { $0.key > $1.key }
    }

    private func load() async {
        isLoading = true
        do {
            analyses = try await APIService.shared.getHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Supporting Types

private struct DateGroup {
    let key: String
    let analyses: [CryAnalysis]
}

private struct HistoryRowView: View {
    let analysis: CryAnalysis

    var body: some View {
        HStack(spacing: 12) {
            Text(labelEmoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(labelName)
                    .font(.headline)
                Text(formattedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(analysis.confidence * 100))%")
                .font(.caption.bold())
                .foregroundStyle(labelColor)
        }
    }

    private var cryLabel: CryLabel? { CryLabel(rawValue: analysis.label) }
    private var labelEmoji: String { cryLabel?.displayName.prefix(2).description ?? "❓" }
    private var labelName: String { cryLabel?.displayName ?? analysis.label.capitalized }
    private var labelColor: Color { cryLabel?.color ?? .secondary }

    private var formattedTime: String {
        let iso = ISO8601DateFormatter()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let date = iso.date(from: analysis.createdAt) ?? Date()
        return formatter.string(from: date)
    }
}
