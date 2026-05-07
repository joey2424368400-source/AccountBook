import Foundation
import Security

final class AuthService {
    static let shared = AuthService()

    private let accessTokenKey = "com.accountbook.accessToken"
    private let refreshTokenKey = "com.accountbook.refreshToken"
    private let serviceName = "com.accountbook.auth"

    var isLoggedIn: Bool {
        (try? getAccessToken()) != nil
    }

    var currentEmail: String? {
        UserDefaults.standard.string(forKey: "auth_email")
    }

    var currentDisplayName: String? {
        UserDefaults.standard.string(forKey: "auth_displayName")
    }

    var currentUserId: Int? {
        let id = UserDefaults.standard.integer(forKey: "auth_userId")
        return id > 0 ? id : nil
    }

    // MARK: - Token 存取 (Keychain)

    func saveAuth(accessToken: String, refreshToken: String, userId: Int, email: String, displayName: String?) {
        saveToKeychain(key: accessTokenKey, value: accessToken)
        saveToKeychain(key: refreshTokenKey, value: refreshToken)
        UserDefaults.standard.set(email, forKey: "auth_email")
        UserDefaults.standard.set(displayName ?? email, forKey: "auth_displayName")
        UserDefaults.standard.set(userId, forKey: "auth_userId")
    }

    func getAccessToken() throws -> String {
        return try readFromKeychain(key: accessTokenKey)
    }

    func getRefreshToken() throws -> String {
        return try readFromKeychain(key: refreshTokenKey)
    }

    func refreshToken() async throws -> String {
        let currentRefresh = try getRefreshToken()

        let body = RefreshRequest(refreshToken: currentRefresh)
        let response: AuthResponse = try await APIService.shared.post(
            "/auth/refresh",
            body: body,
            requiresAuth: false
        )

        saveToKeychain(key: accessTokenKey, value: response.token)
        saveToKeychain(key: refreshTokenKey, value: response.refreshToken)

        return response.token
    }

    func logout() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: "auth_email")
        UserDefaults.standard.removeObject(forKey: "auth_displayName")
        UserDefaults.standard.removeObject(forKey: "auth_userId")
    }

    // MARK: - Keychain 操作

    private func saveToKeychain(key: String, value: String) {
        deleteFromKeychain(key: key)

        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func readFromKeychain(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "AuthService", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Keychain read failed"])
        }
        return value
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - 认证 DTO

struct AuthResponse: Decodable {
    let token: String
    let refreshToken: String
    let user: UserInfo?
}

struct UserInfo: Decodable {
    let id: Int
    let email: String
    let displayName: String?
}

struct RefreshRequest: Encodable {
    let refreshToken: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let displayName: String?
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}
