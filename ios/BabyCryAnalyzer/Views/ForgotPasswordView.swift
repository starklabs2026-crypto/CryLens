import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var alertMessage: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "envelope.badge")
                            .font(.system(size: 42))
                            .foregroundStyle(.tint)
                            .symbolRenderingMode(.hierarchical)

                        Text("Reset your password")
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text("Enter your email and we’ll send you reset instructions.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))

                    Button {
                        Task {
                            await authService.resetPassword(email: email)
                            alertMessage = authService.errorMessage
                            authService.errorMessage = nil
                        }
                    } label: {
                        Group {
                            if authService.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Reset Link")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: .rect(cornerRadius: 16))
                        .foregroundStyle(.white)
                    }
                    .disabled(authService.isLoading)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(backgroundView)
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert(alertTitle, isPresented: isShowingAlert) {
            Button("OK") {
                let message = alertMessage
                alertMessage = nil

                if message == successMessage {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var isShowingAlert: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    alertMessage = nil
                }
            }
        )
    }

    private var alertTitle: String {
        alertMessage == successMessage ? "Check your inbox" : "Error"
    }

    private var successMessage: String {
        "Password reset email sent. Check your inbox."
    }

    private var backgroundView: some View {
        ZStack {
            Color.black

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    .black, .blue.opacity(0.6), .indigo.opacity(0.4),
                    .purple.opacity(0.35), .black, .blue.opacity(0.2),
                    .black, .indigo.opacity(0.3), .black
                ]
            )
            .blur(radius: 70)
            .opacity(0.85)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
