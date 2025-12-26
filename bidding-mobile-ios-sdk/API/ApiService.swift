import Foundation

// swiftlint:disable identifier_name function_parameter_count cyclomatic_complexity type_body_length
// 'os' is a standard parameter name in API contexts
// Function parameter counts and complexity are acceptable for API service methods

private enum ValidationResult {
    case success
    case failure(errors: [String])
}

/// API service - event ve performance tracking
internal final class ApiService {

    private let client: ApiClient
    private let environment: SDKEnvironment
    private weak var errorCallback: MimedaSDKErrorCallback?

    private let eventBaseURL: String
    private let performanceBaseURL: String

    /// - Parameters:
    ///   - client: HTTP client
    ///   - environment: environment
    ///   - errorCallback: error callback
    init(
        client: ApiClient,
        environment: SDKEnvironment,
        errorCallback: MimedaSDKErrorCallback? = nil
    ) {
        self.client = client
        self.environment = environment
        self.errorCallback = errorCallback
        self.eventBaseURL = environment.eventBaseURL
        self.performanceBaseURL = environment.performanceBaseURL
    }

    /// - Parameter eventType: Event type
    private func getBaseURL(for eventType: EventType) -> String {
        switch eventType {
        case .event:
            return eventBaseURL
        case .performance:
            return performanceBaseURL
        }
    }

    private func validateEventParams(
        eventName: EventName,
        eventParameter: EventParameter,
        params: EventParams,
        appName: String,
        deviceId: String,
        os: String,
        language: String,
        sessionId: String?,
        anonymousId: String?
    ) -> ValidationResult {
        var errors: [String] = []

        if SDKConfig.sdkVersion.isEmpty { errors.append("v (SdkVersion) is required") }
        if appName.isEmpty { errors.append("app (AppId) is required") }
        if deviceId.isEmpty { errors.append("d (DeviceId) is required") }
        if os.isEmpty { errors.append("os (Os) is required") }
        if language.isEmpty { errors.append("lng (Language) is required") }
        if sessionId?.isEmpty ?? true { errors.append("s (SessionId) is required") }
        if anonymousId?.isEmpty ?? true { errors.append("aid (AnonymousId) is required") }
        if eventName.value.isEmpty { errors.append("en (EventName) is required") }
        if eventParameter.value.isEmpty { errors.append("ep (EventParameter) is required") }

        return errors.isEmpty ? .success : .failure(errors: errors)
    }

    /// Performance event validate
    private func validatePerformanceEventParams(
        params: PerformanceEventParams,
        appName: String,
        deviceId: String,
        os: String,
        language: String,
        sessionId: String?,
        anonymousId: String?
    ) -> ValidationResult {
        var errors: [String] = []

        if SDKConfig.sdkVersion.isEmpty { errors.append("v (SdkVersion) is required") }
        if appName.isEmpty { errors.append("app (AppId) is required") }
        if deviceId.isEmpty { errors.append("d (DeviceId) is required") }
        if os.isEmpty { errors.append("os (Os) is required") }
        if language.isEmpty { errors.append("lng (Language) is required") }
        if sessionId?.isEmpty ?? true { errors.append("s (SessionId) is required") }
        if anonymousId?.isEmpty ?? true { errors.append("aid (AnonymousId) is required") }
        if params.lineItemId.isEmpty { errors.append("li (LineItemId) is required") }
        if params.creativeId.isEmpty { errors.append("c (CreativeId) is required") }
        if params.adUnit.isEmpty { errors.append("au (AdUnit) is required") }
        if params.productSku.isEmpty { errors.append("psku (ProductSku) is required") }
        if params.payload.isEmpty { errors.append("pyl (Payload) is required") }

        return errors.isEmpty ? .success : .failure(errors: errors)
    }

    /// Event query params
    private func buildEventQueryParams(
        eventName: EventName,
        eventParameter: EventParameter,
        params: EventParams,
        appName: String,
        deviceId: String,
        os: String,
        language: String,
        sessionId: String?,
        anonymousId: String?
    ) -> [String: String] {
        var queryParams: [String: String] = [:]
        let traceId = UUID().uuidString
        let timestamp = String(Int64(Date().timeIntervalSince1970 * 1000))

        queryParams["v"] = SDKConfig.sdkVersion
        queryParams["app"] = appName
        queryParams["t"] = timestamp
        queryParams["d"] = deviceId
        queryParams["os"] = os
        queryParams["lng"] = language
        queryParams["en"] = eventName.value
        queryParams["ep"] = eventParameter.value
        queryParams["tid"] = traceId

        if let anonymousId = anonymousId { queryParams["aid"] = anonymousId }
        if let userId = params.userId { queryParams["uid"] = userId }
        if let lineItemIds = params.lineItemIds { queryParams["li"] = lineItemIds }
        if let productList = params.productList { queryParams["pl"] = productList }
        if let sessionId = sessionId { queryParams["s"] = sessionId }
        if let categoryId = params.categoryId { queryParams["ct"] = categoryId }
        if let keyword = params.keyword { queryParams["kw"] = keyword }
        if let loyaltyCard = params.loyaltyCard { queryParams["lc"] = loyaltyCard }
        if let transactionId = params.transactionId { queryParams["trans"] = transactionId }
        if let totalRowCount = params.totalRowCount { queryParams["trc"] = String(totalRowCount) }

        return queryParams
    }

    /// Performance event query params
    private func buildPerformanceQueryParams(
        params: PerformanceEventParams,
        appName: String,
        deviceId: String,
        os: String,
        language: String,
        sessionId: String?,
        anonymousId: String?
    ) -> [String: String] {
        var queryParams: [String: String] = [:]
        let traceId = UUID().uuidString
        let timestamp = String(Int64(Date().timeIntervalSince1970 * 1000))

        queryParams["v"] = SDKConfig.sdkVersion
        queryParams["li"] = params.lineItemId
        queryParams["c"] = params.creativeId
        queryParams["au"] = params.adUnit
        queryParams["psku"] = params.productSku
        queryParams["pyl"] = params.payload
        queryParams["t"] = timestamp
        queryParams["os"] = os
        queryParams["app"] = appName
        queryParams["d"] = deviceId
        queryParams["lng"] = language
        queryParams["tid"] = traceId

        if let keyword = params.keyword { queryParams["kw"] = keyword }
        if let anonymousId = anonymousId { queryParams["aid"] = anonymousId }
        if let userId = params.userId { queryParams["uid"] = userId }
        if let sessionId = sessionId { queryParams["s"] = sessionId }

        return queryParams
    }

    private func buildURL(baseURL: String, path: String, queryParams: [String: String]) -> URL? {
        var components = URLComponents(string: "\(baseURL)/\(path)")

        var queryItems: [URLQueryItem] = []
        for (key, value) in queryParams where !value.isEmpty {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components?.queryItems = queryItems

        return components?.url
    }

    private func executeWithRetry(url: URL, eventName: String = "") -> Bool {
        var retryCount = 0
        let maxRetries = SDKConfig.maxRetries
        let baseDelay = SDKConfig.retryBaseDelayMs

        while retryCount <= maxRetries {
            let result = client.getSync(url: url)

            switch result {
            case .success(let response):
                let statusCode = response.statusCode

                if (200...299).contains(statusCode) {
                    if !eventName.isEmpty {
                        Logger.s("Event tracked successfully. Event: \(eventName), Status: \(statusCode)")
                    }
                    return true
                } else {
                    if (400...499).contains(statusCode) {
                        if !eventName.isEmpty {
                            Logger.e("Event tracking failed. Event: \(eventName), Status: \(statusCode)")
                        }
                        return false
                    }

                    if retryCount == maxRetries {
                        if !eventName.isEmpty {
                            Logger.e("Event tracking failed after retries. Event: \(eventName), Status: \(statusCode)")
                        }
                        return false
                    }
                }

            case .failure(let error):
                if retryCount == maxRetries {
                    if !eventName.isEmpty {
                        Logger.e("Network error after retries. Event: \(eventName)", error)
                    }
                    return false
                }
            }

            retryCount += 1
            if retryCount <= maxRetries {
                let delay = baseDelay * (1 << (retryCount - 1))
                Thread.sleep(forTimeInterval: Double(delay) / 1000.0)
            }
        }

        return false
    }

    /// Event tracking
    @discardableResult
    func trackEvent(
        eventName: EventName,
        eventParameter: EventParameter,
        params: EventParams,
        eventType: EventType,
        appName: String,
        deviceId: String,
        os: String,
        language: String,
        sessionId: String?,
        anonymousId: String?
    ) -> Bool {
        let validationResult = validateEventParams(
            eventName: eventName,
            eventParameter: eventParameter,
            params: params,
            appName: appName,
            deviceId: deviceId,
            os: os,
            language: language,
            sessionId: sessionId,
            anonymousId: anonymousId
        )

        if case .failure(let errors) = validationResult {
            let errorMessage = "Event validation failed. Event: \(eventName.value)/\(eventParameter.value), " +
                "Errors: \(errors.joined(separator: ", "))"
            Logger.e(errorMessage)
            errorCallback?.onValidationFailed(eventName: eventName, errors: errors)
            return true
        }

        let baseURL = getBaseURL(for: eventType)
        let queryParams = buildEventQueryParams(
            eventName: eventName,
            eventParameter: eventParameter,
            params: params,
            appName: appName,
            deviceId: deviceId,
            os: os,
            language: language,
            sessionId: sessionId,
            anonymousId: anonymousId
        )

        guard let url = buildURL(baseURL: baseURL, path: "events", queryParams: queryParams) else {
            Logger.e("Failed to build URL for event: \(eventName.value)/\(eventParameter.value)")
            return false
        }

        let success = executeWithRetry(url: url, eventName: "\(eventName.value)/\(eventParameter.value)")

        if !success {
            errorCallback?.onEventTrackingFailed(
                eventName: eventName,
                eventParameter: eventParameter,
                error: ApiError.unknown
            )
        }

        return success
    }

    /// Performance event tracking
    @discardableResult
    func trackPerformanceEvent(
        eventType: PerformanceEventType,
        params: PerformanceEventParams,
        appName: String,
        deviceId: String,
        os: String,
        language: String,
        sessionId: String?,
        anonymousId: String?
    ) -> Bool {
        let validationResult = validatePerformanceEventParams(
            params: params,
            appName: appName,
            deviceId: deviceId,
            os: os,
            language: language,
            sessionId: sessionId,
            anonymousId: anonymousId
        )

        if case .failure(let errors) = validationResult {
            let errorMessage = "Performance event validation failed. Event Type: \(eventType), " +
                "Errors: \(errors.joined(separator: ", "))"
            Logger.e(errorMessage)
            errorCallback?.onValidationFailed(eventName: nil, errors: errors)
            return true
        }

        let endpoint = eventType.endpoint
        let queryParams = buildPerformanceQueryParams(
            params: params,
            appName: appName,
            deviceId: deviceId,
            os: os,
            language: language,
            sessionId: sessionId,
            anonymousId: anonymousId
        )

        guard let url = buildURL(baseURL: performanceBaseURL, path: endpoint, queryParams: queryParams) else {
            Logger.e("Failed to build URL for performance event: \(eventType)")
            return false
        }

        let success = executeWithRetry(url: url, eventName: "Performance/\(eventType)")

        if !success {
            errorCallback?.onPerformanceEventTrackingFailed(
                eventType: eventType,
                error: ApiError.unknown
            )
        }

        return success
    }
}

