import SwiftUI

struct SignInView: View {
    @Environment(AuthService.self) private var authService
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp: Bool = false
    @State private var showForgotPassword: Bool = false

    var body: some View {
        ZStack {
            authBackground

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)

                    Text("Baby Cry Analyzer")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Your baby's voice, understood.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))

                    Button("Forgot password?") {
                        showForgotPassword = true
                    }
                    .font(.footnote.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .foregroundStyle(.secondary)

                    Button(action: {
                        Task {
                            await authService.signIn(email: email, password: password)
                        }
                    }) {
                        Group {
                            if authService.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
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

                    Divider()
                        .overlay(.white.opacity(0.1))
                        .padding(.vertical, 8)

                    Button("Don't have an account? Sign Up") {
                        showSignUp = true
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                    Text("Your data is stored securely and never shared.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(22)
                .background(.regularMaterial, in: .rect(cornerRadius: 28))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.vertical, 28)
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: isShowingError) {
            Button("OK") {
                authService.errorMessage = nil
            }
        } message: {
            Text(authService.errorMessage ?? "")
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { authService.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    authService.errorMessage = nil
                }
            }
        )
    }

    private var authBackground: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    .black, .blue.opacity(0.7), .indigo.opacity(0.55),
                    .purple.opacity(0.45), .black, .blue.opacity(0.3),
                    .black, .indigo.opacity(0.4), .black
                ]
            )
            .blur(radius: 70)
            .opacity(0.85)
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}
