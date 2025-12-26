import Foundation

/// Event enums
public enum EventParameter: String {
    case view = "view"
    case addToCart = "addtocart"
    case addToFavorites = "addtofavorites"
    case success = "success"

    public var value: String {
        return self.rawValue
    }
}

