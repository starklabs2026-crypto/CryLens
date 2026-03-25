import Foundation
import OSLog

// MARK: - OpenAI response types

private struct OpenAIChatRequest: Encodable {
    let model: String
    let messages: [OpenAIMessage]
    let response_format: ResponseFormat

    struct ResponseFormat: Encodable {
        let type: String = "json_object"
    }
}

private struct OpenAIMessage: Encodable {
    let role: String
    let content: String
}

private struct OpenAIChatResponse: Decodable {
    let choices: [Choice]
    struct Choice: Decodable {
        let message: Message
        struct Message: Decodable {
            let content: String
        }
    }
}

// MARK: - Parsed analysis response from GPT

private struct CryAnalysisGPTResponse: Decodable {
    let reason: String
    let confidence: Double
    let tip: String
    let detailedAnalysis: String
    let urgency: String
    let recommendations: [String]
}

// MARK: - Service

@MainActor
class CryAnalysisService {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BabyCryAnalyzer", category: "CryAnalysis")
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let maxRetries = 2

    func analyzeCry(
        durationSeconds: Int,
        averageDecibels: Float,
        peakDecibels: Float,
        transcript: String? = nil,
        transcriptLanguage: String? = nil
    ) async throws -> CryAnalysis {
        let apiKey = AppConfig.openAIAPIKey
        guard !apiKey.isEmpty, !apiKey.hasPrefix("sk-YOUR") else {
            logger.error("OpenAI API key not configured — using local fallback")
            return fallbackAnalysis(
                durationSeconds: durationSeconds,
                averageDecibels: averageDecibels,
                peakDecibels: peakDecibels,
                transcript: transcript,
                transcriptLanguage: transcriptLanguage
            )
        }

        let prompt = buildPrompt(
            durationSeconds: durationSeconds,
            averageDecibels: averageDecibels,
            peakDecibels: peakDecibels,
            transcript: transcript,
            transcriptLanguage: transcriptLanguage
        )

        var lastError: Error?
        for attempt in 0...maxRetries {
            if attempt > 0 {
                try await Task.sleep(for: .seconds(Double(attempt)))
            }
            do {
                let gptResponse = try await callOpenAI(prompt: prompt, apiKey: apiKey)
                let urgency = CryUrgency(rawValue: gptResponse.urgency.lowercased()) ?? .low
                let reason = CryReason(rawValue: gptResponse.reason) ?? .unknown
                return CryAnalysis(
                    reason: reason,
                    confidence: gptResponse.confidence,
                    tip: gptResponse.tip,
                    durationSeconds: durationSeconds,
                    averageDecibels: averageDecibels,
                    transcript: transcript,
                    transcriptLanguage: transcriptLanguage,
                    detailedAnalysis: gptResponse.detailedAnalysis,
                    urgency: urgency,
                    recommendations: gptResponse.recommendations
                )
            } catch {
                lastError = error
                logger.error("Attempt \(attempt + 1) failed: \(error.localizedDescription)")
            }
        }

        logger.error("Falling back to local analysis after OpenAI failure: \(lastError?.localizedDescription ?? "unknown")")
        return fallbackAnalysis(
            durationSeconds: durationSeconds,
            averageDecibels: averageDecibels,
            peakDecibels: peakDecibels,
            transcript: transcript,
            transcriptLanguage: transcriptLanguage
        )
    }

    // MARK: - OpenAI call

    private func callOpenAI(prompt: String, apiKey: String) async throws -> CryAnalysisGPTResponse {
        let requestBody = OpenAIChatRequest(
            model: "gpt-4o",
            messages: [OpenAIMessage(role: "user", content: prompt)],
            response_format: .init()
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CryAnalysisError.serverError(0)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("OpenAI HTTP \(httpResponse.statusCode): \(body, privacy: .private)")
            throw CryAnalysisError.serverError(httpResponse.statusCode)
        }

        let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            throw CryAnalysisError.decodingError
        }

        return try JSONDecoder().decode(CryAnalysisGPTResponse.self, from: contentData)
    }

    // MARK: - Prompt

    private func buildPrompt(
        durationSeconds: Int,
        averageDecibels: Float,
        peakDecibels: Float,
        transcript: String?,
        transcriptLanguage: String?
    ) -> String {
        let intensity: String
        if averageDecibels > -15 {
            intensity = "very loud and intense"
        } else if averageDecibels > -25 {
            intensity = "moderately loud"
        } else if averageDecibels > -35 {
            intensity = "soft and gentle"
        } else {
            intensity = "very quiet, almost whimpering"
        }

        let durationDesc: String
        if durationSeconds < 10 {
            durationDesc = "very brief (under 10 seconds)"
        } else if durationSeconds < 30 {
            durationDesc = "short (about \(durationSeconds) seconds)"
        } else if durationSeconds < 60 {
            durationDesc = "moderate duration (\(durationSeconds) seconds)"
        } else {
            durationDesc = "prolonged (over \(durationSeconds / 60) minute\(durationSeconds >= 120 ? "s" : ""))"
        }

        let transcriptContext: String
        if let transcript, !transcript.isEmpty {
            let languageNote = transcriptLanguage?.isEmpty == false ? " in \(transcriptLanguage!)" : ""
            transcriptContext = "- Detected vocal content\(languageNote): \(transcript)"
        } else {
            transcriptContext = "- Detected vocal content: none or unintelligible"
        }

        return """
        You are a pediatric care assistant AI. A parent has recorded their baby crying. Analyze the audio characteristics and provide a detailed, helpful report.

        Audio characteristics:
        - Duration: \(durationDesc)
        - Intensity: \(intensity)
        - Average volume: \(String(format: "%.1f", averageDecibels)) dB
        - Peak volume: \(String(format: "%.1f", peakDecibels)) dB
        \(transcriptContext)

        Cry pattern reference:
        - Hungry: rhythmic, repetitive, builds in intensity over time, moderate volume
        - Tired: whiny, intermittent, lower sustained intensity
        - Pain: sudden, sharp, high-pitched, very intense peak, brief bursts
        - Uncomfortable (wet/temperature): fussy, intermittent, moderate
        - Gassy: short bursts with pauses, moderate intensity
        - Needs Attention: moderate, stop-and-start pattern
        - Overstimulated: builds gradually, fussy before full crying

        Respond ONLY with a JSON object using this exact schema:
        {
          "reason": "<one of: Hungry, Tired, Uncomfortable, Needs Attention, Pain, Gassy, Overstimulated, Unknown>",
          "confidence": <0.0 to 1.0>,
          "tip": "<warm, concise tip for the parent in 1-2 sentences>",
          "detailedAnalysis": "<3-4 sentence detailed explanation: what the audio patterns indicate, why this classification was chosen, and what the baby is likely experiencing>",
          "urgency": "<one of: low, medium, high — high only if Pain or potential medical concern>",
          "recommendations": ["<actionable step 1>", "<actionable step 2>", "<actionable step 3>"]
        }
        """
    }

    // MARK: - Local fallback

    private func fallbackAnalysis(
        durationSeconds: Int,
        averageDecibels: Float,
        peakDecibels: Float,
        transcript: String?,
        transcriptLanguage: String?
    ) -> CryAnalysis {
        let reason: CryReason
        let confidence: Double
        let tip: String
        let detailedAnalysis: String
        let urgency: CryUrgency
        let recommendations: [String]

        if peakDecibels > -8 || (averageDecibels > -18 && durationSeconds < 12) {
            reason = .pain
            confidence = 0.74
            tip = "A sudden, intense cry can sometimes signal pain or sharp discomfort. Check for anything causing immediate distress."
            detailedAnalysis = "The audio shows a very high peak volume and short, intense burst pattern — consistent with a pain response. This type of cry is typically sudden and piercing. Check for physical causes such as a pinched skin, gas pain, or ear discomfort. If the crying persists or you notice other symptoms, consult your pediatrician."
            urgency = .high
            recommendations = [
                "Check for physical discomfort: pinched skin, hair tourniquet, insect bite",
                "Look for signs of ear pain (pulling at ears)",
                "Contact your pediatrician if intense crying continues for more than 10 minutes"
            ]
        } else if durationSeconds > 50 && averageDecibels > -24 {
            reason = .hungry
            confidence = 0.71
            tip = "This pattern lines up with hunger cues. Try a feeding if it's been a while."
            detailedAnalysis = "The cry is sustained and moderately loud, which aligns with a hunger pattern. Hungry cries typically build in intensity the longer they are ignored. Check when your baby last fed and look for additional hunger cues like rooting or sucking on hands."
            urgency = .medium
            recommendations = [
                "Try feeding your baby",
                "Check when they last ate — newborns typically feed every 2-3 hours",
                "Look for hunger cues like rooting, sucking fists, or lip smacking"
            ]
        } else if durationSeconds > 35 && averageDecibels <= -24 {
            reason = .tired
            confidence = 0.69
            tip = "A longer, softer cry often appears when babies are overtired. Try starting a calming sleep routine."
            detailedAnalysis = "The cry duration is extended but the volume is relatively low, which is characteristic of an overtired or sleepy baby. Overtired babies often have difficulty self-soothing, which can prolong crying. Reducing stimulation and creating a calm environment may help."
            urgency = .low
            recommendations = [
                "Dim lights and reduce noise in the environment",
                "Try swaddling and gentle rocking",
                "Start a consistent sleep routine if not already in place"
            ]
        } else if durationSeconds < 15 && peakDecibels < -20 {
            reason = .gassy
            confidence = 0.65
            tip = "Short bursts can sometimes happen with gas or tummy discomfort. Gentle burping may help."
            detailedAnalysis = "The short, intermittent cry pattern with moderate intensity is often associated with gas or digestive discomfort. Babies frequently swallow air during feeding, which can cause pain in the digestive tract. Physical techniques to help move gas are often very effective."
            urgency = .low
            recommendations = [
                "Try gentle bicycle leg movements",
                "Hold baby upright and pat their back to encourage burping",
                "Try a gentle clockwise tummy massage"
            ]
        } else if averageDecibels > -22 {
            reason = .needsAttention
            confidence = 0.64
            tip = "Your baby may be seeking comfort or closeness. Try holding and speaking softly."
            detailedAnalysis = "The cry pattern suggests your baby may simply want closeness or social interaction. Babies at this stage communicate needs almost entirely through crying, and attention-seeking cries are a healthy developmental behavior. Responding promptly builds trust and security."
            urgency = .low
            recommendations = [
                "Hold your baby skin-to-skin if possible",
                "Talk or sing softly to provide reassurance",
                "Check diaper and clothing for comfort"
            ]
        } else {
            reason = .uncomfortable
            confidence = 0.6
            tip = "Your baby may be uncomfortable. Check diaper, clothing, and room temperature."
            detailedAnalysis = "The audio pattern doesn't clearly match a single cause, suggesting general discomfort. Discomfort cries are often fussy and inconsistent. Running through a basic comfort checklist is the best first step to identifying and resolving the cause."
            urgency = .low
            recommendations = [
                "Check and change diaper if needed",
                "Ensure clothing isn't too tight or scratchy",
                "Check room temperature (ideal: 68–72°F / 20–22°C)"
            ]
        }

        return CryAnalysis(
            reason: reason,
            confidence: confidence,
            tip: tip,
            durationSeconds: durationSeconds,
            averageDecibels: averageDecibels,
            transcript: transcript,
            transcriptLanguage: transcriptLanguage,
            detailedAnalysis: detailedAnalysis,
            urgency: urgency,
            recommendations: recommendations
        )
    }
}

nonisolated enum CryAnalysisError: Error, LocalizedError, Sendable {
    case invalidURL
    case serverError(Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Unable to connect to analysis service."
        case .serverError(let code): return "Analysis service returned an error (\(code)). Please try again."
        case .decodingError: return "Unable to process the analysis result."
        }
    }
}
