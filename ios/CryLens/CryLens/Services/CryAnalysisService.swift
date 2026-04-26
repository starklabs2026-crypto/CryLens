import Foundation
import AVFoundation

final class CryAnalysisService: ObservableObject {
    @Published var isAnalysing: Bool = false
    @Published var result: CryLabel?
    @Published var confidence: Double?
    @Published var error: String?

    func analyse(audioURL: URL, babyId: String) async {
        await setState(analysing: true)
        do {
            let fileName = audioURL.lastPathComponent
            let mime = mimeType(for: audioURL)
            let dur  = await audioDuration(url: audioURL)

            let uploadInfo = try await APIService.shared.getUploadURL(
                babyId: babyId, fileName: fileName, mimeType: mime)

            let secured = audioURL.startAccessingSecurityScopedResource()
            defer { if secured { audioURL.stopAccessingSecurityScopedResource() } }

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(audioURL.pathExtension)
            try FileManager.default.copyItem(at: audioURL, to: tempURL)
            defer { try? FileManager.default.removeItem(at: tempURL) }

            try await APIService.shared.uploadAudioFile(
                to: uploadInfo.uploadUrl, fileURL: tempURL, mimeType: mime)

            let analysis = try await APIService.shared.analyzeAudio(
                babyId: babyId, audioPath: uploadInfo.path, durationSec: dur)

            await MainActor.run {
                if let label = CryLabel(rawValue: analysis.label) {
                    self.result = label
                    self.confidence = analysis.confidence
                } else {
                    self.error = "AI returned unsupported label: \(analysis.label)"
                }
                self.isAnalysing = false
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription; self.isAnalysing = false }
        }
    }

    func analyseWithAI(audioURL: URL, babyId: String) async {
        await analyse(audioURL: audioURL, babyId: babyId)
    }

    func reset() { result = nil; confidence = nil; error = nil; isAnalysing = false }

    private func setState(analysing: Bool) async {
        await MainActor.run { isAnalysing = analysing; result = nil; confidence = nil; error = nil }
    }

    private func audioDuration(url: URL) async -> Int {
        do {
            let asset = AVURLAsset(url: url)
            let dur   = try await asset.load(.duration)
            return max(1, Int(CMTimeGetSeconds(dur)))
        } catch { return 5 }
    }

    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "m4a": return "audio/m4a"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        case "aac": return "audio/aac"
        case "mp4": return "audio/mp4"
        default:    return "audio/wav"
        }
    }
}
