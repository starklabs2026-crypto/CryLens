import SwiftUI

struct SignUpView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var localError: String? = nil

    var body: some View {
        ZStack {
            authBackground

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 64))
                        .foregroundStyle(.white)

                    Text("Create Account")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Save your cry history and track your baby's patterns over time.")
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

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color.white.opacity(0.08), in: .rect(cornerRadius: 16))

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color.white.opacity(0.08), in: .rect(cornerRadius: 16))

                    Button {
                        localError = nil
                        authService.errorMessage = nil

                        guard password == confirmPassword else {
                            localError = "Passwords do not match"
                            return
                        }

                        guard password.count >= 8 else {
                            localError = "Password must be at least 8 characters"
                            return
                        }

                        Task {
                            await authService.signUp(email: email, password: password)
                        }
                    } label: {
                        Group {
                            if authService.isLoading {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("Sign Up")
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

                    Button("Already have an account? Sign In") {
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
                if localError != nil {
                    localError = nil
                } else {
                    authService.errorMessage = nil
                }
            }
        } message: {
            Text(displayedAlertMessage ?? "")
        }
    }

    private var displayedAlertMessage: String? {
        localError ?? authService.errorMessage
    }

    private var isShowingAlert: Binding<Bool> {
        Binding(
            get: { displayedAlertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    localError = nil
                    authService.errorMessage = nil
                }
            }
        )
    }

    private var authBackground: some View {
        Color.black.ignoresSafeArea()
    }
}
