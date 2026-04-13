import SwiftUI

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
            VStack(spacing: 24) {
                Spacer()

                // Logo
                Image(systemName: "waveform.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(coral)

                VStack(spacing: 4) {
                    Text("CryLens")
                        .font(.largeTitle.bold())
                    Text("Know what your baby needs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer().frame(height: 8)

                // Fields
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

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button(action: signIn) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(coral)
                            .frame(height: 52)
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                Button {
                    showRegister = true
                } label: {
                    Text("Don't have an account? ")
                        .foregroundStyle(.secondary)
                    + Text("Register")
                        .foregroundStyle(coral)
                }
                .font(.subheadline)

                Spacer()
            }
            .padding(.horizontal, 28)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
        .tint(coral)
    }

    private func signIn() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                let response = try await APIService.shared.login(email: email, password: password)
                await MainActor.run { appState.login(with: response) }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
