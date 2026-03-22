import SwiftUI

struct SignUpView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var alertMessage: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 44))
                            .foregroundStyle(.tint)
                            .symbolRenderingMode(.hierarchical)

                        Text("Create your account")
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text("Save your cry history and continue across sessions.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

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
                    }

                    Button {
                        Task {
                            await authService.signUp(email: email, password: password)

                            if authService.isAuthenticated {
                                dismiss()
                                return
                            }

                            if let message = authService.errorMessage {
                                alertMessage = message
                                authService.errorMessage = nil
                            }
                        }
                    } label: {
                        Group {
                            if authService.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
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
            .navigationTitle("Sign Up")
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
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
        .onChange(of: authService.isAuthenticated) { oldValue, newValue in
            if !oldValue && newValue {
                dismiss()
            }
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
        "Error"
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
                    .black, .blue.opacity(0.65), .indigo.opacity(0.45),
                    .purple.opacity(0.4), .black, .blue.opacity(0.25),
                    .black, .indigo.opacity(0.35), .black
                ]
            )
            .blur(radius: 70)
            .opacity(0.85)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
