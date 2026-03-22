import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""

    var body: some View {
        ZStack {
            authBackground

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)

                    Text("Reset Password")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Enter your email and we'll send you a reset link")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.white.opacity(0.08), in: .rect(cornerRadius: 16))

                    Button {
                        authService.errorMessage = nil

                        Task {
                            await authService.resetPassword(email: email)
                        }
                    } label: {
                        Group {
                            if authService.isLoading {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("Send Reset Link")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white, in: .rect(cornerRadius: 16))
                        .foregroundStyle(.black)
                    }
                    .disabled(authService.isLoading)

                    Divider()
                        .overlay(.white.opacity(0.08))
                        .padding(.vertical, 8)

                    Button("Back to Sign In") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.55))
                }
                .padding(22)
                .background(Color.white.opacity(0.06), in: .rect(cornerRadius: 28))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.vertical, 28)
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: isShowingAlert) {
            Button("OK") {
                let message = authService.errorMessage
                authService.errorMessage = nil

                if message?.localizedCaseInsensitiveContains("sent") == true {
                    dismiss()
                }
            }
        } message: {
            Text(authService.errorMessage ?? "")
        }
    }

    private var isShowingAlert: Binding<Bool> {
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
        Color.black.ignoresSafeArea()
    }
}
