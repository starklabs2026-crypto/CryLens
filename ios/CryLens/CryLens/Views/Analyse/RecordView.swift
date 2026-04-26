import SwiftUI

struct RecordView: View {
    @StateObject private var audioCapture = AudioCaptureService()
    @StateObject private var analysisService = CryAnalysisService()
    @StateObject private var sub = SubscriptionService.shared
    @EnvironmentObject private var appState: AppState

    @State private var selectedBabyId: String?
    @State private var babies: [Baby] = []
    @State private var showFilePicker = false
    @State private var showPaywall = false
    @State private var importError: String?

    private let coral = Color(hex: "FF6B6B")

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {

                // Baby Selector
                if babies.isEmpty {
                    Text("Add a baby in Profile first")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                } else {
                    Picker("Select Baby", selection: $selectedBabyId) {
                        ForEach(babies) { baby in
                            Text(baby.name).tag(Optional(baby.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(coral)
                }

                if !sub.isPro {
                    VStack(spacing: 6) {
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
                    .padding(.horizontal)
                }

                Spacer()

                // Waveform
                if audioCapture.isRecording {
                    WaveformView(audioLevel: audioCapture.audioLevel)
                        .transition(.opacity)
                }

                // Record Button
                Button(action: handleRecordTap) {
                    ZStack {
                        Circle()
                            .fill(audioCapture.isRecording ? coral : Color(.systemGray4))
                            .frame(width: 80, height: 80)
                        Image(systemName: audioCapture.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(audioCapture.isRecording ? .white : .primary)
                    }
                }
                .disabled(analysisService.isAnalysing || babies.isEmpty)

                // Duration
                if audioCapture.isRecording {
                    Text(formattedDuration)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                // Import button — shown when not recording or analysing
                if !audioCapture.isRecording && !analysisService.isAnalysing {
                    Button {
                        importError = nil
                        showFilePicker = true
                    } label: {
                        Label("Import Audio File", systemImage: "square.and.arrow.down")
                            .font(.subheadline)
                            .foregroundStyle(coral)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(coral.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .disabled(babies.isEmpty)
                }

                // Analysing indicator
                if analysisService.isAnalysing {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Analysing cry with AI…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Result Card
                if let label = analysisService.result,
                   let conf = analysisService.confidence,
                   !analysisService.isAnalysing {
                    resultCard(label: label, confidence: conf)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Error messages
                if let err = analysisService.error {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                if let err = importError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("CryLens")
            .animation(.spring(), value: analysisService.result)
            .task {
                await loadBabies()
                await appState.refreshAnalysisUsage()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav, .aiff],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first, let babyId = selectedBabyId else { return }
                    guard canStartAnalysis else {
                        showPaywall = true
                        return
                    }
                    Task {
                        await analysisService.analyseWithAI(audioURL: url, babyId: babyId)
                        if analysisService.error == nil {
                            await appState.refreshAnalysisUsage()
                        }
                    }
                case .failure(let err):
                    importError = err.localizedDescription
                }
            }
        }
    }

    // MARK: - Result Card

    @ViewBuilder
    private func resultCard(label: CryLabel, confidence: Double) -> some View {
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

            Text("\(Int(confidence * 100))% confidence")
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

    private func handleRecordTap() {
        if audioCapture.isRecording {
            guard let url = audioCapture.stopRecording(),
                  let babyId = selectedBabyId else { return }
            Task {
                await analysisService.analyse(audioURL: url, babyId: babyId)
                if analysisService.error == nil {
                    await appState.refreshAnalysisUsage()
                }
                audioCapture.deleteRecording(at: url)
            }
        } else {
            guard canStartAnalysis else {
                showPaywall = true
                return
            }
            Task {
                let granted = await audioCapture.requestPermission()
                if granted { audioCapture.startRecording() }
            }
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
