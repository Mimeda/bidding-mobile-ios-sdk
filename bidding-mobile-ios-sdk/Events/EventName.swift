import Foundation

public enum EventName: String {
    case home
    case listing
    case search
    case pdp
    case cart
    case purchase

    public var value: String {
        return self.rawValue
    }
}

