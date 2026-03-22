import SwiftUI

@MainActor
@Observable
class CryHistoryStore {
    var analyses: [CryAnalysis] = []

    private let userId: String

    private var fileURL: URL {
        let directory: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("cry_analyses_\(userId).json")
    }

    init(userId: String = "local") {
        self.userId = userId
        load()
    }

    func add(_ analysis: CryAnalysis) {
        analyses.insert(analysis, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        analyses.remove(atOffsets: offsets)
        save()
    }

    func clearAll() {
        analyses.removeAll()
        save()
    }

    var groupedByDate: [(String, [CryAnalysis])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: analyses) { analysis in
            calendar.startOfDay(for: analysis.date)
        }

        return grouped.sorted { $0.key > $1.key }.map { (key, value) in
            let formatter = DateFormatter()
            if calendar.isDateInToday(key) {
                return ("Today", value.sorted { $0.date > $1.date })
            } else if calendar.isDateInYesterday(key) {
                return ("Yesterday", value.sorted { $0.date > $1.date })
            } else {
                formatter.dateStyle = .medium
                return (formatter.string(from: key), value.sorted { $0.date > $1.date })
            }
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(analyses) else { return }
        try? data.write(to: fileURL, options: .completeFileProtection)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            analyses = []
            return
        }

        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([CryAnalysis].self, from: data) else { return }
        analyses = decoded
    }
}
