import Foundation

public struct PerformanceEventParams {
    public let app: String?
    public let lineItemId: String?
    public let creativeId: String?
    public let adUnit: String?
    public let productSku: String?
    public let payload: String?
    public let keyword: String?
    public let userId: String?

    public init(
        app: String? = nil,
        lineItemId: String? = nil,
        creativeId: String? = nil,
        adUnit: String? = nil,
        productSku: String? = nil,
        payload: String? = nil,
        keyword: String? = nil,
        userId: String? = nil
    ) {
        self.app = app
        self.lineItemId = lineItemId
        self.creativeId = creativeId
        self.adUnit = adUnit
        self.productSku = productSku
        self.payload = payload
        self.keyword = keyword
        self.userId = userId
    }
}

