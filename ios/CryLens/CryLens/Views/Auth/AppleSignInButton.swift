import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    let onCredential: (String, String?) -> Void  // (identityToken, fullName)
    let onError: (String) -> Void

    var body: some View {
        SignInWithAppleButtonRep(onCredential: onCredential, onError: onError)
            .frame(height: 52)
            .cornerRadius(14)
    }
}

// MARK: - UIViewRepresentable

private struct SignInWithAppleButtonRep: UIViewRepresentable {
    let onCredential: (String, String?) -> Void
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCredential: onCredential, onError: onError)
    }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = 14
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    // MARK: Coordinator

    final class Coordinator: NSObject,
                              ASAuthorizationControllerDelegate,
                              ASAuthorizationControllerPresentationContextProviding {
        let onCredential: (String, String?) -> Void
        let onError: (String) -> Void

        init(
            onCredential: @escaping (String, String?) -> Void,
            onError: @escaping (String) -> Void
        ) {
            self.onCredential = onCredential
            self.onError = onError
        }

        @objc func handleTap() {
            let provider = ASAuthorizationAppleIDProvider()
            let request  = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        func authorizationController(controller: ASAuthorizationController,
                                     didCompleteWithAuthorization authorization: ASAuthorization) {
            guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = cred.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else { return }

            var fullName: String?
            if let first = cred.fullName?.givenName {
                fullName = [first, cred.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
            }

            onCredential(token, fullName)
        }

        func authorizationController(controller: ASAuthorizationController,
                                     didCompleteWithError error: Error) {
            onError(error.localizedDescription)
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
