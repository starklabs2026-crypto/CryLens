import Foundation

final class CryAnalysisService: ObservableObject {
    @Published var isAnalysing: Bool = false
    @Published var result: CryLabel?
    @Published var confidence: Double?
    @Published var error: String?

    func analyse(audioURL: URL, babyId: String) async {
        await MainActor.run {
            isAnalysing = true
            result = nil
            confidence = nil
            error = nil
        }

        do {
            // Simulate analysis delay
            try await Task.sleep(nanoseconds: 1_500_000_000)

            // TODO: replace random selection with Core ML model inference in v2
            let label = CryLabel.allCases.randomElement()!
            let conf = Double.random(in: 0.75...0.99)

            let durationSec = Int((try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? Int) ?? 5)

            let newAnalysis = NewCryAnalysis(
                babyId: babyId,
                label: label.rawValue,
                confidence: conf,
                durationSec: durationSec,
                notes: nil
            )

            _ = try await APIService.shared.logAnalysis(newAnalysis)

            await MainActor.run {
                self.result = label
                self.confidence = conf
                self.isAnalysing = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isAnalysing = false
            }
        }
    }

    func reset() {
        result = nil
        confidence = nil
        error = nil
        isAnalysing = false
    }
}
