import SwiftUI
import Observation

@Observable
final class AuthViewModel {
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?

    var email = ""
    var password = ""
    var confirmPassword = ""
    var displayName = ""

    private let authService = AuthService.shared
    private let apiService = APIService.shared

    init() {
        isAuthenticated = authService.isLoggedIn
    }

    var canLogin: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var canRegister: Bool {
        !email.isEmpty && password.count >= 6 && password == confirmPassword
    }

    func login() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let body = LoginRequest(email: email, password: password)
            let response: AuthResponse = try await apiService.post(
                "/auth/login",
                body: body,
                requiresAuth: false
            )
            authService.saveAuth(
                accessToken: response.token,
                refreshToken: response.refreshToken,
                userId: response.user?.id ?? 0,
                email: email,
                displayName: response.user?.displayName
            )
            isAuthenticated = true
            clearFields()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "登录失败，请稍后重试"
        }
    }

    func register() async {
        guard password == confirmPassword else {
            errorMessage = "两次密码输入不一致"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "密码至少需要6个字符"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let body = RegisterRequest(email: email, password: password, displayName: displayName.isEmpty ? nil : displayName)
            let response: AuthResponse = try await apiService.post(
                "/auth/register",
                body: body,
                requiresAuth: false
            )
            authService.saveAuth(
                accessToken: response.token,
                refreshToken: response.refreshToken,
                userId: response.user?.id ?? 0,
                email: email,
                displayName: response.user?.displayName
            )
            isAuthenticated = true
            clearFields()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "注册失败，请稍后重试"
        }
    }

    func logout() {
        authService.logout()
        isAuthenticated = false
    }

    private func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
    }
}
