import Foundation

public enum PerformanceEventType {
    case impression
    case click

    internal var endpoint: String {
        switch self {
        case .impression:
            return "impressions"
        case .click:
            return "clicks"
        }
    }
}

