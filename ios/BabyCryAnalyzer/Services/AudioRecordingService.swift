import SwiftUI
import AVFoundation
import Accelerate

@MainActor
@Observable
class AudioRecordingService: NSObject, AVAudioRecorderDelegate {
    var isRecording = false
    var audioLevels: [Float] = Array(repeating: 0, count: 30)
    var currentDecibels: Float = -60
    var recordingDuration: Int = 0
    var hasPermission = false

    private let maxRecordingDuration: Int = 300
    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var durationTimer: Timer?
    private var decibelSamples: [Float] = []

    var recordingURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("baby_cry_recording.m4a")
    }

    var averageDecibels: Float {
        guard !decibelSamples.isEmpty else { return -60 }
        return decibelSamples.reduce(0, +) / Float(decibelSamples.count)
    }

    func requestPermission() async {
        if #available(iOS 17.0, *) {
            hasPermission = await AVAudioApplication.requestRecordPermission()
        } else {
            hasPermission = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            return
        }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: recordingURL.path
            )
            isRecording = true
            recordingDuration = 0
            decibelSamples = []
            startMetering()
        } catch {
            return
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        stopMetering()
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        isRecording = false
    }

    private func startMetering() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateLevels()
            }
        }
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.recordingDuration += 1
                if self.recordingDuration >= self.maxRecordingDuration {
                    self.stopRecording()
                }
            }
        }
    }

    private func stopMetering() {
        levelTimer?.invalidate()
        levelTimer = nil
        durationTimer?.invalidate()
        durationTimer = nil
        audioLevels = Array(repeating: 0, count: 30)
        currentDecibels = -60
    }

    private func updateLevels() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()

        let db = recorder.averagePower(forChannel: 0)
        let normalizedLevel = max(0, (db + 60) / 60)
        currentDecibels = db
        decibelSamples.append(db)
        if decibelSamples.count > 500 {
            decibelSamples.removeFirst()
        }

        var newLevels = audioLevels
        newLevels.removeFirst()
        newLevels.append(normalizedLevel)
        audioLevels = newLevels
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            isRecording = false
        }
    }
}
