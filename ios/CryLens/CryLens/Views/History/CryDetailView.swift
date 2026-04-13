import SwiftUI

struct CryDetailView: View {
    let analysis: CryAnalysis

    private var cryLabel: CryLabel? { CryLabel(rawValue: analysis.label) }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Large emoji
                Text(cryLabel?.displayName.prefix(2).description ?? "❓")
                    .font(.system(size: 80))

                // Label
                Text(cryLabel?.displayName ?? analysis.label.capitalized)
                    .font(.title.bold())
                    .foregroundStyle(cryLabel?.color ?? .primary)

                // Confidence bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Confidence")
                            .font(.subheadline.bold())
                        Spacer()
                        Text("\(Int(analysis.confidence * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: analysis.confidence)
                        .tint(cryLabel?.color ?? .blue)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)

                // Details grid
                detailRow(label: "Duration", value: "\(analysis.durationSec)s")
                detailRow(label: "Date", value: formattedDate)

                if let notes = analysis.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.subheadline.bold())
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                }

                if let label = cryLabel {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What this means")
                            .font(.subheadline.bold())
                        Text(label.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                }
            }
            .padding(20)
        }
        .navigationTitle("Cry Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    private var formattedDate: String {
        let iso = ISO8601DateFormatter()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let date = iso.date(from: analysis.createdAt) ?? Date()
        return formatter.string(from: date)
    }
}
