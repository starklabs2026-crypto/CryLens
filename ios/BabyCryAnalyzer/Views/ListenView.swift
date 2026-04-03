import SwiftUI

struct ListenView: View {
    var store: StoreViewModel
    @State private var viewModel = ListenViewModel()
    @State private var showFilePicker: Bool = false
    @State private var showPaywall: Bool = false
    @Environment(CryHistoryStore.self) private var historyStore

    private let freeAnalysisLimit: Int = 10

    private var usageLimitApplies: Bool {
        store.isAvailable && !store.isPremium
    }

    private var freeUsageExhausted: Bool {
        usageLimitApplies && historyStore.analyses.count >= freeAnalysisLimit
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    VStack(spacing: 8) {
                        Text(statusTitle)
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())

                        Text(statusSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .animation(.smooth(duration: 0.3), value: viewModel.recorder.isRecording)

                    Spacer().frame(height: 48)

                    ZStack {
                        Circle()
                            .fill(
                                MeshGradient(
                                    width: 3,
                                    height: 3,
                                    points: [
                                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                                    ],
                                    colors: [
                                        .purple.opacity(0.15), .indigo.opacity(0.1), .blue.opacity(0.08),
                                        .pink.opacity(0.12), .purple.opacity(0.08), .indigo.opacity(0.1),
                                        .orange.opacity(0.06), .pink.opacity(0.1), .purple.opacity(0.12)
                                    ]
                                )
                            )
                            .frame(width: 240, height: 240)
                            .blur(radius: 40)
                            .opacity(viewModel.recorder.isRecording ? 1 : 0.5)
                            .scaleEffect(viewModel.recorder.isRecording ? 1.2 : 0.9)
                            .animation(
                                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: viewModel.recorder.isRecording
                            )

                        VStack(spacing: 20) {
                            RecordButton(
                                isRecording: viewModel.recorder.isRecording,
                                isAnalyzing: viewModel.isAnalyzing,
                                action: {
                                    if freeUsageExhausted {
                                        showPaywall = true
                                    } else {
                                        viewModel.toggleRecording(historyStore: historyStore)
                                    }
                                }
                            )

                            if viewModel.recorder.isRecording {
                                Text(viewModel.formattedDuration)
                                    .font(.system(.title2, design: .rounded, weight: .light))
                                    .foregroundStyle(.secondary)
                                    .contentTransition(.numericText())
                                    .animation(.default, value: viewModel.recorder.recordingDuration)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                    }
                    .frame(height: 280)

                    WaveformView(
                        levels: viewModel.recorder.audioLevels,
                        isActive: viewModel.recorder.isRecording
                    )
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                    HStack {
                        Rectangle().frame(height: 0.5).foregroundStyle(.secondary.opacity(0.4))
                        Text("or").font(.caption).foregroundStyle(.secondary)
                        Rectangle().frame(height: 0.5).foregroundStyle(.secondary.opacity(0.4))
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)

                    Button(action: {
                        if freeUsageExhausted {
                            showPaywall = true
                        } else {
                            showFilePicker = true
                        }
                    }) {
                        Label("Upload Audio File", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(.rect(cornerRadius: 20))
                    }
                    .disabled(viewModel.recorder.isRecording || viewModel.isAnalyzing)
                    .padding(.top, 8)

                    if usageLimitApplies {
                        let remaining = max(0, freeAnalysisLimit - historyStore.analyses.count)
                        Text("\(remaining) free analyses remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 12)
                    } else if !store.isAvailable {
                        Text("Unlimited analyses available in this build")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 12)
                    }

                    if viewModel.isAnalyzing {
                        if let fileName = viewModel.selectedFileName {
                            VStack(spacing: 4) {
                                ProgressView()
                                    .tint(.secondary)
                                Text("Analyzing \(fileName)…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 24)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(.secondary)
                                Text("Analyzing cry patterns…")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.top, 24)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }

                    if let analysis = viewModel.latestAnalysis {
                        AnalysisResultCard(analysis: analysis)
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                )
                            )
                    }

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle("Listen")
            .navigationBarTitleDisplayMode(.large)
        }
        .animation(.spring(duration: 0.5), value: viewModel.isAnalyzing)
        .animation(.spring(duration: 0.5), value: viewModel.latestAnalysis?.id)
        .animation(.spring(duration: 0.5), value: viewModel.recorder.isRecording)
        .task {
            await viewModel.requestMicPermission()
        }
        .alert("Oops", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
        .overlay {
            if !viewModel.recorder.hasPermission && !viewModel.recorder.isRecording {
                permissionOverlay
            }
        }
        .sheet(isPresented: $showFilePicker) {
            AudioFilePicker(
                onFilePicked: { url in
                    showFilePicker = false
                    Task {
                        await viewModel.analyzeFile(url: url, historyStore: historyStore)
                    }
                },
                onCancel: {
                    showFilePicker = false
                }
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store)
        }
    }

    private var statusTitle: String {
        if viewModel.recorder.isRecording { return "Listening" }
        return "Hush"
    }

    private var statusSubtitle: String {
        if viewModel.isAnalyzing { return "Understanding your baby's needs" }
        if viewModel.recorder.isRecording { return "Tap stop when ready to analyze" }
        if viewModel.latestAnalysis != nil { return "Tap the mic to start a new recording" }
        return "Tap the microphone to begin"
    }

    private var permissionOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "mic.slash")
                    .font(.system(size: 44, weight: .thin))
                    .foregroundStyle(.tertiary)

                VStack(spacing: 8) {
                    Text("Microphone Access")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text("Enable microphone access in Settings to record and analyze your baby's crying.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(.label))
            }
            .padding(40)
        }
    }
}
