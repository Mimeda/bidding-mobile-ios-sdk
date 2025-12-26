import Foundation

internal final class ApiClient {

    private let session: URLSession
    private let apiKey: String
    private let packageName: String

    /// - Parameters:
    ///   - apiKey: API Key
    ///   - packageName: Uygulama paket adı
    init(apiKey: String, packageName: String) {
        self.apiKey = apiKey
        self.packageName = packageName

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = SDKConfig.readTimeout
        configuration.timeoutIntervalForResource = SDKConfig.writeTimeout

        self.session = URLSession(configuration: configuration)
    }

    /// URL'i loglama için güvenli hale getirir - query parametrelerini maskele
    /// - Parameter url: Loglanacak URL
    /// - Returns: Query parametreleri maskelenmiş URL string
    private func sanitizeURLForLogging(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }

        // Query parametrelerini kaldır
        components.queryItems = nil

        // Sadece scheme, host ve path bilgisini döndür
        if let sanitizedURL = components.url {
            // Query parametreleri varsa maskele
            if url.query != nil {
                return "\(sanitizedURL.absoluteString)?***"
            }
            return sanitizedURL.absoluteString
        }

        // Fallback: sadece scheme ve host
        if let scheme = url.scheme, let host = url.host {
            return "\(scheme)://\(host)\(url.path)?***"
        }

        return url.absoluteString
    }

    /// - Parameters:
    ///   - apiKey: API Key
    ///   - packageName: Uygulama paket adı
    static func createClient(apiKey: String, packageName: String) -> ApiClient {
        return ApiClient(apiKey: apiKey, packageName: packageName)
    }

    /// - Parameters:
    ///   - url: Request URL
    ///   - completion: result callback
    func get(url: URL, completion: @escaping (Result<HTTPURLResponse, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Headers
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(packageName, forHTTPHeaderField: "X-Package-Name")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        Logger.d("Request: GET \(sanitizeURLForLogging(url))")

        let task = session.dataTask(with: request) { data, response, error in
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

    /// - Parameter url: Request URL
    func getSync(url: URL) -> Result<HTTPURLResponse, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(packageName, forHTTPHeaderField: "X-Package-Name")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        Logger.d("Request: GET \(sanitizeURLForLogging(url))")

        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<HTTPURLResponse, Error>!

        let task = session.dataTask(with: request) { data, response, error in
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

        return result
    }

    /// URLSession invalidate
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
