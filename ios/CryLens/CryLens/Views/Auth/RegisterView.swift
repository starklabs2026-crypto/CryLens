import SwiftUI
import GoogleSignIn

struct RegisterView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let coral = Color(hex: "FF6B6B")

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Image(systemName: "waveform.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundStyle(coral)

                VStack(spacing: 4) {
                    Text("Create Account")
                        .font(.largeTitle.bold())
                    Text("Start understanding your baby")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer().frame(height: 4)

                VStack(spacing: 16) {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                    SecureField("Password (min 8 characters)", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button(action: register) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(coral)
                            .frame(height: 52)
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .disabled(name.isEmpty || email.isEmpty || password.count < 8 || isLoading)

                // Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(Color(.systemGray5))
                    Text("or").font(.caption).foregroundStyle(.secondary)
                    Rectangle().frame(height: 1).foregroundStyle(Color(.systemGray5))
                }

                // Apple Sign In
                AppleSignInButton { token, appleNameFromApple in
                    Task { await signInWithApple(token: token, name: name.isEmpty ? appleNameFromApple : name) }
                }

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

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .tint(coral)
    }

    private func register() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                let response = try await APIService.shared.register(name: name, email: email, password: password)
                await MainActor.run { appState.login(with: response) }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
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
