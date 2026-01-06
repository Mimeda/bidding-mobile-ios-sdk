import Foundation

internal final class ApiClient {

    private let session: URLSession
    private let obfuscatedApiKey: [UInt8]
    private let packageName: String

    init(apiKey: String, packageName: String) {
        self.obfuscatedApiKey = ApiClient.obfuscate(apiKey)
        self.packageName = packageName

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = SDKConfig.readTimeout
        configuration.timeoutIntervalForResource = SDKConfig.writeTimeout

        self.session = URLSession(configuration: configuration)
    }
    
    private var apiKey: String {
        return ApiClient.deobfuscate(obfuscatedApiKey)
    }
    
    private static func obfuscate(_ string: String) -> [UInt8] {
        guard let data = string.data(using: .utf8) else {
            return []
        }
        let key: UInt8 = 0x5A
        return data.map { $0 ^ key }
    }
    
    private static func deobfuscate(_ obfuscated: [UInt8]) -> String {
        let key: UInt8 = 0x5A
        let deobfuscated = obfuscated.map { $0 ^ key }
        let data = Data(deobfuscated)
        guard let string = String(data: data, encoding: .utf8) else {
            return SecureStorage.getString("api_key") ?? ""
        }
        return string
    }

    private func sanitizeURLForLogging(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }

        components.queryItems = nil

        if let sanitizedURL = components.url {
            if url.query != nil {
                return "\(sanitizedURL.absoluteString)?***"
            }
            return sanitizedURL.absoluteString
        }
        if let scheme = url.scheme, let host = url.host {
            return "\(scheme)://\(host)\(url.path)?***"
        }

        return url.absoluteString
    }

    static func createClient(apiKey: String, packageName: String) -> ApiClient {
        return ApiClient(apiKey: apiKey, packageName: packageName)
    }

    func get(url: URL, completion: @escaping (Result<HTTPURLResponse, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(packageName, forHTTPHeaderField: "X-Package-Name")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        Logger.d("Request: GET \(sanitizeURLForLogging(url))")

        let task = session.dataTask(with: request) { _, response, error in
            if let error = error {
                Logger.e("Request failed: \(error.localizedDescription)", error)
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                let error = ApiError.invalidResponse
                Logger.e("Invalid response type")
                completion(.failure(error))
                return
            }

            Logger.d("Response: \(httpResponse.statusCode)")
            completion(.success(httpResponse))
        }

        task.resume()
    }

    func getSync(url: URL) -> Result<HTTPURLResponse, Error> {
        if Thread.isMainThread {
            Logger.e("getSync cannot be called on main thread as it would block the app")
            return .failure(ApiError.networkError(NSError(domain: "ApiClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "getSync cannot be called on main thread"])))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(packageName, forHTTPHeaderField: "X-Package-Name")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        Logger.d("Request: GET \(sanitizeURLForLogging(url))")

        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<HTTPURLResponse, Error>? = nil

        let task = session.dataTask(with: request) { _, response, error in
            defer { semaphore.signal() }

            if let error = error {
                Logger.e("Request failed: \(error.localizedDescription)", error)
                result = .failure(error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                let error = ApiError.invalidResponse
                Logger.e("Invalid response type")
                result = .failure(error)
                return
            }

            Logger.d("Response: \(httpResponse.statusCode)")
            result = .success(httpResponse)
        }

        task.resume()
        semaphore.wait()

        guard let finalResult = result else {
            Logger.e("Unexpected error: result is nil after semaphore wait")
            return .failure(ApiError.unknown)
        }

        return finalResult
    }

    func invalidate() {
        session.invalidateAndCancel()
    }
}

internal enum ApiError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case networkError(Error)
    case timeout
    case validationFailed(errors: [String])
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response received"
        case .httpError(let statusCode, let message):
            return "HTTP Error \(statusCode): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out"
        case .validationFailed(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

