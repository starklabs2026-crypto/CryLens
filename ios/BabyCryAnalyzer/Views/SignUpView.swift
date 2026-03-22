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
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)

                    Text("Create Account")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Save your cry history and track your baby's patterns over time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))

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
                                    .tint(.white)
                            } else {
                                Text("Sign Up")
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

                    Button("Already have an account? Sign In") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
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
