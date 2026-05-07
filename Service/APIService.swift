import Foundation

enum APIError: LocalizedError {
    case networkError(String)
    case serverError(String)
    case unauthorized
    case decodingError
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return msg
        case .serverError(let msg): return msg
        case .unauthorized: return "登录已过期，请重新登录"
        case .decodingError: return "数据解析错误"
        case .invalidURL: return "无效的请求地址"
        }
    }
}

final class APIService: @unchecked Sendable {
    static let shared = APIService()

    var baseURL: String {
        UserDefaults.standard.string(forKey: "api_base_url") ?? "http://localhost:3000/api"
    }

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func request<T: Decodable>(
        method: String,
        path: String,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            if let token = try? AuthService.shared.getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try? encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("网络连接失败，请检查网络设置")
        }

        if httpResponse.statusCode == 401 && requiresAuth {
            // 尝试刷新 token 后重试一次
            let newToken = try await AuthService.shared.refreshToken()
            request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            let (retryData, retryResponse) = try await session.data(for: request)
            guard let retryHttp = retryResponse as? HTTPURLResponse else {
                throw APIError.networkError("网络连接失败，请检查网络设置")
            }
            if retryHttp.statusCode == 401 {
                throw APIError.unauthorized
            }
            guard retryHttp.statusCode >= 200 && retryHttp.statusCode < 300 else {
                let errorBody = String(data: retryData, encoding: .utf8) ?? ""
                throw APIError.serverError("请求失败 (\(retryHttp.statusCode)): \(errorBody)")
            }
            do {
                return try decoder.decode(T.self, from: retryData)
            } catch {
                throw APIError.decodingError
            }
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            if let err = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(err.error)
            }
            throw APIError.serverError("请求失败 (\(httpResponse.statusCode))")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    // GET 请求快捷方法
    func get<T: Decodable>(_ path: String, requiresAuth: Bool = true) async throws -> T {
        try await request(method: "GET", path: path, body: nil as String?, requiresAuth: requiresAuth)
    }

    // POST 请求快捷方法
    func post<T: Decodable, B: Encodable>(_ path: String, body: B, requiresAuth: Bool = true) async throws -> T {
        try await request(method: "POST", path: path, body: body, requiresAuth: requiresAuth)
    }
}

struct ErrorResponse: Decodable {
    let error: String
}
