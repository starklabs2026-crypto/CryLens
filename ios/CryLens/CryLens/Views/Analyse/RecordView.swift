import SwiftUI
import AVFoundation

struct RecordView: View {
    @StateObject private var audioCapture = AudioCaptureService()
    @StateObject private var analysisService = CryAnalysisService()
    @StateObject private var sub = SubscriptionService.shared
    @EnvironmentObject private var appState: AppState

    @State private var selectedBabyId: String?
    @State private var babies: [Baby] = []
    @State private var showFilePicker = false
    @State private var showPaywall = false
    @State private var selectedAnalysis: CryAnalysis?
    @State private var importError: String?
    @State private var isFinishingRecording = false

    private let coral = Color(hex: "FF6B6B")
    private let peach = Color(hex: "FFB36B")
    private let mint = Color(hex: "63D8B3")
    private let lavender = Color(hex: "8A7CFF")

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    babySelector

                    if !sub.isPro {
                        usageBanner
                    }

                    capturePanel

                    if analysisService.isAnalysing {
                        analysingIndicator
                    }

                    if let analysis = analysisService.currentAnalysis,
                       let label = CryLabel(rawValue: analysis.label),
                       !analysisService.isAnalysing {
                        resultCard(analysis: analysis, label: label)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    errorPanel
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 110)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        coral.opacity(0.045),
                        mint.opacity(0.035)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("CryLens")
            .animation(.spring(), value: analysisService.result)
            .animation(.easeInOut(duration: 0.2), value: audioCapture.isRecording)
            .onChange(of: audioCapture.durationSeconds) { seconds in
                if seconds >= AudioCaptureService.maximumDurationSeconds {
                    finishRecording()
                }
            }
            .task {
                await loadBabies()
                await appState.refreshAnalysisUsage()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedAnalysis) { analysis in
                NavigationStack {
                    CryDetailView(analysis: analysis)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    selectedAnalysis = nil
                                }
                            }
                        }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
        }
    }

    private var babySelector: some View {
        VStack(spacing: 10) {
            if babies.isEmpty {
                Label("Add a baby in Profile first", systemImage: "person.crop.circle.badge.plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 10) {
                    ForEach(Array([coral, peach, mint, lavender].enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                    }

                    Picker("Select Baby", selection: $selectedBabyId) {
                        ForEach(babies) { baby in
                            Text(baby.name).tag(Optional(baby.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(coral)
                    .font(.title3.weight(.semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.white.opacity(0.82))
                .clipShape(Capsule())
                .shadow(color: coral.opacity(0.08), radius: 14, y: 8)
            }
        }
    }

    private var usageBanner: some View {
        VStack(spacing: 7) {
            Text(appState.remainingFreeAnalyses > 0
                 ? "\(appState.remainingFreeAnalyses) free analyses left"
                 : "Free analyses used")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(appState.remainingFreeAnalyses > 0 ? coral : .red)

            Text(appState.remainingFreeAnalyses > 0
                 ? "Try CryLens before subscribing. After \(appState.freeAnalysisLimit) analyses, Pro is required."
                 : "Upgrade to CryLens Pro to keep analysing new recordings.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var capturePanel: some View {
        VStack(spacing: 22) {
            CryCaptureMascotView(
                isRecording: audioCapture.isRecording,
                audioLevel: audioCapture.audioLevel
            )
            .padding(.top, 8)

            VStack(spacing: 6) {
                Text(audioCapture.isRecording ? "Listening for baby cry" : "Record a clear baby cry")
                    .font(.title3.weight(.bold))

                Text(audioCapture.isRecording
                     ? "Keep the phone near the baby. Recording stops after \(AudioCaptureService.maximumDurationSeconds) seconds."
                     : "Capture \(acceptableDurationText) of clear crying in a quiet room for best results.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: handleRecordTap) {
                ZStack {
                    Circle()
                        .fill(audioCapture.isRecording ? coral : Color(.label))
                        .frame(width: 86, height: 86)
                        .shadow(color: (audioCapture.isRecording ? coral : Color.black).opacity(0.18), radius: 18, y: 10)

                    Image(systemName: audioCapture.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .disabled(analysisService.isAnalysing || babies.isEmpty || isFinishingRecording)

            if audioCapture.isRecording {
                VStack(spacing: 8) {
                    HStack {
                        Text(formattedDuration)
                        Spacer()
                        Text(maxDurationText)
                    }
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.secondary)

                    ProgressView(
                        value: Double(audioCapture.durationSeconds),
                        total: Double(AudioCaptureService.maximumDurationSeconds)
                    )
                    .tint(coral)
                }
                .transition(.opacity)
            }

            if !audioCapture.isRecording && !analysisService.isAnalysing {
                Button {
                    importError = nil
                    showFilePicker = true
                } label: {
                    Label("Import Audio File", systemImage: "square.and.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(coral)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(coral.opacity(0.11))
                        .clipShape(Capsule())
                }
                .disabled(babies.isEmpty)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: coral.opacity(0.10), radius: 22, y: 14)
    }

    private var analysingIndicator: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(coral)

            Text("Checking for a clear baby cry...")
                .font(.subheadline.weight(.medium))

            Text("This may take a few seconds.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var errorPanel: some View {
        if let err = analysisService.error ?? importError {
            VStack(spacing: 10) {
                Image(systemName: "waveform.badge.exclamationmark")
                    .font(.title2)
                    .foregroundStyle(coral)

                Text(err)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(coral.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    // MARK: - Result Card

    @ViewBuilder
    private func resultCard(analysis: CryAnalysis, label: CryLabel) -> some View {
        VStack(spacing: 16) {
            Image(systemName: label.symbolName)
                .font(.system(size: 56))
                .foregroundStyle(label.color)

            Text(label.displayName)
                .font(.title2.bold())
                .foregroundStyle(label.color)

            Text(label.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Button("Read more") {
                selectedAnalysis = analysis
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(label.color)

            Text("\(Int(analysis.confidence * 100))% confidence")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(label.color.opacity(0.15))
                .foregroundStyle(label.color)
                .clipShape(Capsule())

            Button("Log Another") {
                analysisService.reset()
            }
            .buttonStyle(.bordered)
            .tint(coral)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Helpers

    private var formattedDuration: String {
        let s = audioCapture.durationSeconds
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private var maxDurationText: String {
        "Max \(AudioCaptureService.maximumDurationSeconds)s"
    }

    private var acceptableDurationText: String {
        "\(AudioCaptureService.minimumDurationSeconds)-\(AudioCaptureService.maximumDurationSeconds) seconds"
    }

    private func handleRecordTap() {
        if audioCapture.isRecording {
            finishRecording()
        } else {
            guard canStartAnalysis else {
                showPaywall = true
                return
            }
            importError = nil
            analysisService.reset()
            Task {
                let granted = await audioCapture.requestPermission()
                if granted { audioCapture.startRecording() }
            }
        }
    }

    private func finishRecording() {
        guard audioCapture.isRecording, !isFinishingRecording else { return }
        isFinishingRecording = true

        guard let url = audioCapture.stopRecording(),
              let babyId = selectedBabyId else {
            isFinishingRecording = false
            return
        }

        let duration = audioCapture.durationSeconds
        guard duration >= AudioCaptureService.minimumDurationSeconds else {
            audioCapture.deleteRecording(at: url)
            importError = "That recording was too short. Please try again with \(acceptableDurationText) of clear baby crying."
            isFinishingRecording = false
            return
        }

        Task {
            await analysisService.analyse(audioURL: url, babyId: babyId)
            if analysisService.error == nil {
                await appState.refreshAnalysisUsage()
            }
            audioCapture.deleteRecording(at: url)
            await MainActor.run {
                isFinishingRecording = false
            }
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first, let babyId = selectedBabyId else { return }
            guard canStartAnalysis else {
                showPaywall = true
                return
            }

            importError = nil
            analysisService.reset()

            Task {
                let duration = await audioDuration(url: url)

                guard duration >= AudioCaptureService.minimumDurationSeconds else {
                    await MainActor.run {
                        importError = "That clip is too short. Please import \(acceptableDurationText) of clear baby crying."
                    }
                    return
                }

                guard duration <= AudioCaptureService.maximumDurationSeconds else {
                    await MainActor.run {
                        importError = "That clip is too long. Please trim it to \(acceptableDurationText) before importing."
                    }
                    return
                }

                await analysisService.analyseWithAI(audioURL: url, babyId: babyId)
                if analysisService.error == nil {
                    await appState.refreshAnalysisUsage()
                }
            }

        case .failure(let err):
            importError = err.localizedDescription
        }
    }

    private func audioDuration(url: URL) async -> Int {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }

        do {
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            guard seconds.isFinite else { return 0 }
            return max(1, Int(seconds.rounded(.up)))
        } catch {
            return 0
        }
    }

    private func loadBabies() async {
        #if DEBUG
        if DebugLaunchOptions.isScreenshotMode {
            babies = DebugLaunchOptions.screenshotBabies
            if selectedBabyId == nil { selectedBabyId = babies.first?.id }
            return
        }
        #endif

        do {
            babies = try await APIService.shared.getBabies()
            if selectedBabyId == nil { selectedBabyId = babies.first?.id }
        } catch {}
    }

    private var canStartAnalysis: Bool {
        sub.isPro || appState.hasFreeAnalysisAccess
    }
}

private struct CryCaptureMascotView: View {
    let isRecording: Bool
    let audioLevel: Float

    @State private var pulse = false

    private let coral = Color(hex: "FF6B6B")
    private let peach = Color(hex: "FFB36B")
    private let mint = Color(hex: "63D8B3")
    private let lavender = Color(hex: "8A7CFF")

    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        [coral, peach, lavender][index].opacity(isRecording ? 0.30 : 0.16),
                        lineWidth: 2
                    )
                    .scaleEffect(isRecording && pulse ? 1.08 + CGFloat(index) * 0.14 : 0.94 + CGFloat(index) * 0.08)
                    .opacity(isRecording ? 0.70 - Double(index) * 0.18 : 0.36)
            }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [coral, peach],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 132, height: 132)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.42), lineWidth: 10)
                        .blur(radius: 1)
                }
                .shadow(color: coral.opacity(isRecording ? 0.28 : 0.18), radius: 24, y: 14)

            HStack(spacing: 6) {
                ForEach(0..<9) { index in
                    Capsule()
                        .fill(.white)
                        .frame(width: 5, height: barHeight(index))
                        .animation(.easeInOut(duration: 0.16), value: audioLevel)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                }
            }

            Image(systemName: "sparkle")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .offset(x: 44, y: -42)

            Circle()
                .fill(mint)
                .frame(width: 13, height: 13)
                .offset(x: -50, y: 45)

            Circle()
                .fill(lavender.opacity(0.9))
                .frame(width: 9, height: 9)
                .offset(x: -45, y: -48)
        }
        .frame(width: 190, height: 190)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private func barHeight(_ index: Int) -> CGFloat {
        let baseline: [CGFloat] = [24, 38, 52, 66, 78, 66, 52, 38, 24]
        guard isRecording else { return baseline[index] * 0.72 }

        let level = CGFloat(max(0.12, min(audioLevel, 1.0)))
        let wave = pulse ? CGFloat(index % 3) * 4 : CGFloat((8 - index) % 3) * 4
        return max(20, baseline[index] * (0.62 + level * 0.72) + wave)
    }
}
