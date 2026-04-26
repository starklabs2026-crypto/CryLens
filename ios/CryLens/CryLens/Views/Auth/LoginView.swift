import SwiftUI
import GoogleSignIn

struct LoginView: View {
    @EnvironmentObject private var appState: AppState

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRegister = false

    private let coral = Color(hex: "FF6B6B")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    Image(systemName: "waveform.circle.fill")
                        .resizable().scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(coral)

                    VStack(spacing: 4) {
                        Text("CryLens").font(.largeTitle.bold())
                        Text("Know what your baby needs")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }

                    Spacer().frame(height: 4)

                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    if let msg = errorMessage {
                        Text(msg).foregroundStyle(.red).font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    // Email sign in
                    Button(action: signIn) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14).fill(coral).frame(height: 52)
                            if isLoading { ProgressView().tint(.white) }
                            else { Text("Sign In").font(.headline).foregroundStyle(.white) }
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)

                    // Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(Color(.systemGray5))
                        Text("or").font(.caption).foregroundStyle(.secondary)
                        Rectangle().frame(height: 1).foregroundStyle(Color(.systemGray5))
                    }

                    // Apple Sign In
                    AppleSignInButton(
                        onCredential: { token, name in
                            signInWithApple(token: token, name: name)
                        },
                        onError: { message in
                            errorMessage = message
                        }
                    )

                    // Google Sign In
                    Button(action: signInWithGoogle) {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill").foregroundStyle(.blue)
                            Text("Continue with Google").font(.headline).foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Color(.systemBackground))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 1))
                        .cornerRadius(14)
                    }

                    Button {
                        showRegister = true
                    } label: {
                        Text("Don't have an account? ").foregroundColor(.secondary)
                        + Text("Register").foregroundColor(coral)
                    }
                    .font(.subheadline)

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 28)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showRegister) { RegisterView() }
        }
        .tint(coral)
    }

    private func signIn() {
        Task {
            isLoading = true; errorMessage = nil
            do {
                let r = try await APIService.shared.login(email: email, password: password)
                await MainActor.run { appState.login(with: r) }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
            }
        }
    }

    private func signInWithApple(token: String, name: String?) {
        Task {
            isLoading = true; errorMessage = nil
            do {
                let r = try await APIService.shared.loginWithApple(identityToken: token, name: name)
                await MainActor.run { appState.login(with: r) }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
            }
        }
    }

    private func signInWithGoogle() {
        guard AppConfig.isGoogleSignInConfigured else {
            errorMessage = "Google Sign-In is not configured."
            return
        }

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        Task {
            isLoading = true; errorMessage = nil
            do {
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
                guard let idToken = result.user.idToken?.tokenString else {
                    await MainActor.run { errorMessage = "Failed to get Google ID token."; isLoading = false }
                    return
                }
                let r = try await APIService.shared.loginWithGoogle(idToken: idToken)
                await MainActor.run { appState.login(with: r) }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
            }
        }
    }
}
