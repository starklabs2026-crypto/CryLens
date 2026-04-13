import Foundation
import AVFoundation

final class AudioCaptureService: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var audioLevel: Float = 0.0
    @Published var durationSeconds: Int = 0

    private var recorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var durationTimer: Timer?
    private var outputURL: URL?

    // MARK: - Permission

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Recording

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            return
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        outputURL = tempURL

        let settings: [String: Any] = [
            AVFormatIDKey:             Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey:           44100,
            AVNumberOfChannelsKey:     1,
            AVEncoderAudioQualityKey:  AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: tempURL, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
        } catch {
            return
        }

        isRecording = true
        durationSeconds = 0

        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let rec = self.recorder else { return }
            rec.updateMeters()
            let power = rec.averagePower(forChannel: 0)
            // averagePower ranges roughly from -160 dB (silence) to 0 dB (max)
            let normalised = max(0, (power + 80) / 80)
            self.audioLevel = normalised
        }

        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.durationSeconds += 1
        }
    }

    func stopRecording() -> URL? {
        recorder?.stop()
        recorder = nil
        levelTimer?.invalidate()
        levelTimer = nil
        durationTimer?.invalidate()
        durationTimer = nil
        isRecording = false
        audioLevel = 0.0

        try? AVAudioSession.sharedInstance().setActive(false)

        return outputURL
    }

    // MARK: - Cleanup

    func deleteRecording(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
