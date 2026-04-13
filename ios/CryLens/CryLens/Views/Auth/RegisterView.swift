import SwiftUI

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
        VStack(spacing: 24) {
            Spacer()

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

            Spacer().frame(height: 8)

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

            Spacer()
        }
        .padding(.horizontal, 28)
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
}
