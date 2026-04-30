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

        var groups: [Date: [CryAnalysis]] = [:]

        for a in analyses {
            let date = AppDate.parse(a.createdAt) ?? Date()
            let day = Calendar.current.startOfDay(for: date)
            groups[day, default: []].append(a)
        }

        return groups
            .map { group in
                DateGroup(
                    date: group.key,
                    key: formatter.string(from: group.key),
                    analyses: group.value.sorted {
                        (AppDate.parse($0.createdAt) ?? .distantPast) > (AppDate.parse($1.createdAt) ?? .distantPast)
                    }
                )
            }
            .sorted { $0.date > $1.date }
    }

    private func load() async {
        #if DEBUG
        if DebugLaunchOptions.isScreenshotMode {
            analyses = DebugLaunchOptions.screenshotHistory
            errorMessage = nil
            isLoading = false
            return
        }
        #endif

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
    let date: Date
    let key: String
    let analyses: [CryAnalysis]
}

private struct HistoryRowView: View {
    let analysis: CryAnalysis

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: labelSymbol)
                .font(.title2)
                .foregroundStyle(labelColor)
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
    private var labelSymbol: String { cryLabel?.symbolName ?? "questionmark.circle" }
    private var labelName: String { cryLabel?.displayName ?? analysis.label.capitalized }
    private var labelColor: Color { cryLabel?.color ?? .secondary }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let date = AppDate.parse(analysis.createdAt) ?? Date()
        return formatter.string(from: date)
    }
}
