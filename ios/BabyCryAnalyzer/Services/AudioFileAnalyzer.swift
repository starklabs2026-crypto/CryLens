import AVFoundation
import Accelerate

nonisolated enum AudioFileError: Error, LocalizedError, Sendable {
    case tooShort
    case tooLong
    case unreadable
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .tooShort: return "Audio file is too short. Please use a recording of at least 2 seconds."
        case .tooLong: return "Audio file is too long. Please use a recording under 5 minutes."
        case .unreadable: return "Could not read audio file."
        case .unsupportedFormat: return "Unsupported audio format."
        }
    }
}

@MainActor
class AudioFileAnalyzer {
    var isAnalyzing: Bool = false
    var errorMessage: String? = nil

    func analyze(url: URL) async throws -> (durationSeconds: Int, averageDecibels: Float, peakDecibels: Float) {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationSeconds = Int(CMTimeGetSeconds(duration))

        guard durationSeconds >= 2 else { throw AudioFileError.tooShort }
        guard durationSeconds <= 300 else { throw AudioFileError.tooLong }

        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)
        guard frameCount > 0 else { throw AudioFileError.unreadable }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioFileError.unreadable
        }
        try audioFile.read(into: buffer)

        guard let channelData = buffer.floatChannelData else { throw AudioFileError.unsupportedFormat }
        let channelSamples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(buffer.frameLength)))

        let sumOfSquares = channelSamples.reduce(Float(0)) { $0 + $1 * $1 }
        let rms = sqrt(sumOfSquares / Float(channelSamples.count))

        var averageDb: Float = rms > 0 ? 20 * log10(rms) : -60
        var peakDb: Float = channelSamples.map { abs($0) }.max().map { $0 > 0 ? 20 * log10($0) : -60 } ?? -60

        averageDb = min(0, max(-60, averageDb))
        peakDb = min(0, max(-60, peakDb))

        return (durationSeconds, averageDb, peakDb)
    }
}
