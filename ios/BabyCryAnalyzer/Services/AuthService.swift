import SwiftUI
import Supabase

@MainActor
@Observable
class AuthService {
    var isAuthenticated: Bool = false
    var currentUserID: String? = nil
    var isLoading: Bool = false
    var isCheckingSession: Bool = true
    var errorMessage: String? = nil

    init() {
        Task {
            await checkSession()
        }
    }

    private func checkSession() async {
        defer {
            isCheckingSession = false
        }

        let session = try? await supabase.auth.session

        if session != nil {
            isAuthenticated = true
            currentUserID = session?.user.id.uuidString
        } else {
            isAuthenticated = false
            currentUserID = nil
        }
    }

    func signUp(email: String, password: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@") else {
            errorMessage = "Please enter a valid email address."
            return
        }

        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signUp(email: trimmedEmail, password: password)
            isAuthenticated = true
            currentUserID = supabase.auth.currentUser?.id.uuidString
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signIn(email: trimmedEmail, password: password)
            isAuthenticated = true
            currentUserID = supabase.auth.currentUser?.id.uuidString
        } catch {
            errorMessage = "Incorrect email or password."
        }
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        isAuthenticated = false
        currentUserID = nil
    }

    var currentUserEmail: String? {
        supabase.auth.currentUser?.email
    }

    func resetPassword(email: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.resetPasswordForEmail(trimmedEmail)
            errorMessage = "Password reset email sent. Check your inbox."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
