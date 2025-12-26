import Foundation

/// Event enums
public enum EventName: String {
    case home = "home"
    case listing = "listing"
    case search = "search"
    case pdp = "pdp"
    case cart = "cart"
    case purchase = "purchase"

    public var value: String {
        return self.rawValue
    }
}

