import Foundation

internal struct SDKConfig {

    static let sdkVersion = "1.0.1"

    static let connectTimeout: TimeInterval = 10

    static let readTimeout: TimeInterval = 30

    static let writeTimeout: TimeInterval = 30

    static let maxRetries = 3

    static let retryBaseDelayMs: Int = 1000

    static let productionEventBaseURL = "https://event.mlink.com.tr"

    static let productionPerformanceBaseURL = "https://performance.mlink.com.tr"

    static let stagingEventBaseURL = "https://bidding-eventcollector-stage.mlink.com.tr"

    static let stagingPerformanceBaseURL = "https://bidding-prfmnccollector-stage.mlink.com.tr"

    #if DEBUG
    static let debugLogging = true
    #else
    static let debugLogging = false
    #endif

    static let sessionDurationMs: Int = 30 * 60 * 1000
}

