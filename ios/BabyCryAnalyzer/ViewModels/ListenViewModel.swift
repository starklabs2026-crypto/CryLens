import SwiftUI

@MainActor
@Observable
class ListenViewModel {
    var isAnalyzing = false
    var latestAnalysis: CryAnalysis?
    var errorMessage: String?
    var showError = false

    let recorder = AudioRecordingService()
    let fileAnalyzer = AudioFileAnalyzer()
    var isPickingFile: Bool = false
    var selectedFileName: String? = nil

    private let analysisService = CryAnalysisService()

    func toggleRecording(historyStore: CryHistoryStore) {
        if recorder.isRecording {
            stopAndAnalyze(historyStore: historyStore)
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        errorMessage = nil
        recorder.startRecording()
    }

    private func stopAndAnalyze(historyStore: CryHistoryStore) {
        let duration = recorder.recordingDuration
        let avgDb = recorder.averageDecibels
        let peakDb = recorder.currentDecibels
        recorder.stopRecording()

        guard duration >= 2 else {
            errorMessage = "Please record for at least 2 seconds."
            showError = true
            return
        }

        guard avgDb > -55 else {
            errorMessage = "No crying detected. Please hold the phone closer to your baby and try again."
            showError = true
            return
        }

        isAnalyzing = true

        Task {
            do {
                let analysis = try await analysisService.analyzeCry(
                    durationSeconds: duration,
                    averageDecibels: avgDb,
                    peakDecibels: peakDb
                )
                withAnimation(.spring(duration: 0.5)) {
                    latestAnalysis = analysis
                }
                historyStore.add(analysis)
                try? FileManager.default.removeItem(at: recorder.recordingURL)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isAnalyzing = false
        }
    }

    func analyzeFile(url: URL, historyStore: CryHistoryStore) async {
        isAnalyzing = true
        selectedFileName = url.lastPathComponent
        errorMessage = nil

        do {
            let metrics = try await fileAnalyzer.analyze(url: url)

            guard metrics.averageDecibels > -55 else {
                errorMessage = "No crying detected in this file. Please try a different recording."
                showError = true
                isAnalyzing = false
                selectedFileName = nil
                return
            }

            let analysis = try await analysisService.analyzeCry(
                durationSeconds: metrics.durationSeconds,
                averageDecibels: metrics.averageDecibels,
                peakDecibels: metrics.peakDecibels
            )

            withAnimation(.spring(duration: 0.5)) {
                latestAnalysis = analysis
            }
            historyStore.add(analysis)

            try? FileManager.default.removeItem(at: url)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isAnalyzing = false
        selectedFileName = nil
    }

    func requestMicPermission() async {
        await recorder.requestPermission()
    }

    var formattedDuration: String {
        let minutes = recorder.recordingDuration / 60
        let seconds = recorder.recordingDuration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
