import Foundation

enum DebugLaunchOptions {
    #if DEBUG
    private static let env = ProcessInfo.processInfo.environment

    static let isScreenshotMode = env["CRYLENS_SCREENSHOT_MODE"] == "1"
    static let screenshotEmail = env["CRYLENS_SCREENSHOT_EMAIL"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    static let screenshotPassword = env["CRYLENS_SCREENSHOT_PASSWORD"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    static let screenshotTab = env["CRYLENS_SCREENSHOT_TAB"]?.lowercased()
    static let screenshotSettingsFocus = env["CRYLENS_SCREENSHOT_SETTINGS_FOCUS"]?.lowercased()
    static let showPaywall = env["CRYLENS_SCREENSHOT_SHOW_PAYWALL"] == "1"
    #else
    static let isScreenshotMode = false
    static let screenshotEmail: String? = nil
    static let screenshotPassword: String? = nil
    static let screenshotTab: String? = nil
    static let screenshotSettingsFocus: String? = nil
    static let showPaywall = false
    #endif
}

#if DEBUG
extension DebugLaunchOptions {
    static let screenshotUser = User(
        id: "debug-user",
        name: "Nalin",
        email: "appstore-demo-20260426@crylens.app"
    )

    static let screenshotBabies: [Baby] = [
        Baby(
            id: "debug-baby-aarav",
            userId: "debug-user",
            name: "Aarav",
            dob: "2025-11-12T00:00:00.000Z",
            createdAt: "2026-04-20T08:00:00.000Z"
        ),
        Baby(
            id: "debug-baby-mira",
            userId: "debug-user",
            name: "Mira",
            dob: "2026-02-03T00:00:00.000Z",
            createdAt: "2026-04-21T08:00:00.000Z"
        )
    ]

    static let screenshotHistory: [CryAnalysis] = [
        CryAnalysis(
            id: "debug-analysis-1",
            babyId: "debug-baby-mira",
            label: "tired",
            confidence: 0.92,
            durationSec: 18,
            notes: "Fussy cry with yawning between cries.",
            audioUrl: nil,
            createdAt: "2026-04-26T09:12:00.000Z"
        ),
        CryAnalysis(
            id: "debug-analysis-2",
            babyId: "debug-baby-mira",
            label: "hungry",
            confidence: 0.88,
            durationSec: 24,
            notes: "Rhythmic short cry before feeding.",
            audioUrl: nil,
            createdAt: "2026-04-26T06:45:00.000Z"
        ),
        CryAnalysis(
            id: "debug-analysis-3",
            babyId: "debug-baby-aarav",
            label: "burping",
            confidence: 0.8,
            durationSec: 14,
            notes: "Settled quickly after burping.",
            audioUrl: nil,
            createdAt: "2026-04-25T16:20:00.000Z"
        ),
        CryAnalysis(
            id: "debug-analysis-4",
            babyId: "debug-baby-mira",
            label: "discomfort",
            confidence: 0.77,
            durationSec: 21,
            notes: "Restless crying before diaper change.",
            audioUrl: nil,
            createdAt: "2026-04-24T19:05:00.000Z"
        )
    ]
}
#endif
