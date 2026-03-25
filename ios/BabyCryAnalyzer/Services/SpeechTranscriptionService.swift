import Foundation
import OSLog
import UniformTypeIdentifiers

nonisolated struct SpeechTranscriptionResponse: Codable, Sendable {
    let text: String
    let language: String
}

nonisolated enum SpeechTranscriptionError: Error, LocalizedError, Sendable {
    case invalidURL
    case invalidAudio
    case missingAPIKey
    case serverError(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to connect to the voice recognition service."
        case .invalidAudio:
            return "This audio file could not be prepared for voice recognition."
        case .missingAPIKey:
            return "OpenAI API key is not configured."
        case .serverError:
            return "Voice recognition is temporarily unavailable."
        case .decodingFailed:
            return "The voice recognition response could not be read."
        }
    }
}

@MainActor
final class SpeechTranscriptionService {
    private let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BabyCryAnalyzer", category: "SpeechTranscription")
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    func transcribeAudio(at url: URL) async throws -> SpeechTranscriptionResponse {
        let apiKey = AppConfig.openAIAPIKey
        guard !apiKey.isEmpty, !apiKey.hasPrefix("sk-YOUR") else {
            throw SpeechTranscriptionError.missingAPIKey
        }

        let audioData = try Data(contentsOf: url)
        guard !audioData.isEmpty else {
            throw SpeechTranscriptionError.invalidAudio
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipartBody(audioData: audioData, fileURL: url, boundary: boundary)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpeechTranscriptionError.serverError(0)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("Whisper HTTP \(httpResponse.statusCode): \(body, privacy: .private)")
            throw SpeechTranscriptionError.serverError(httpResponse.statusCode)
        }

        // Whisper verbose_json response: {"task":..., "language":"english", "text":"..."}
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw SpeechTranscriptionError.decodingFailed
        }

        let language = (json["language"] as? String) ?? ""
        return SpeechTranscriptionResponse(text: text, language: language)
    }

    private func buildMultipartBody(audioData: Data, fileURL: URL, boundary: String) -> Data {
        var body = Data()
        let fileName = fileURL.lastPathComponent.isEmpty ? "recording.m4a" : fileURL.lastPathComponent
        let mime = mimeType(for: fileURL)

        // file field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mime)\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")

        // model field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.append("whisper-1\r\n")

        // response_format field (verbose_json includes language)
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
        body.append("verbose_json\r\n")

        body.append("--\(boundary)--\r\n")
        return body
    }

    private func mimeType(for url: URL) -> String {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return "audio/m4a"
        }
        if type.conforms(to: .wav) { return "audio/wav" }
        if type.conforms(to: .mpeg4Audio) { return "audio/m4a" }
        if type.conforms(to: .mp3) { return "audio/mpeg" }
        if type.conforms(to: .audio) { return type.preferredMIMEType ?? "audio/m4a" }
        return "audio/m4a"
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
