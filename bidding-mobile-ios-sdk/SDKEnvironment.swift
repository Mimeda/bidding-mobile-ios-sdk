import Foundation

public enum SDKEnvironment {
    case production
    
    case staging
    
    internal var eventBaseURL: String {
        switch self {
        case .production:
            return SDKConfig.productionEventBaseURL
        case .staging:
            return SDKConfig.stagingEventBaseURL
        }
    }
    
    internal var performanceBaseURL: String {
        switch self {
        case .production:
            return SDKConfig.productionPerformanceBaseURL
        case .staging:
            return SDKConfig.stagingPerformanceBaseURL
        }
    }
}

