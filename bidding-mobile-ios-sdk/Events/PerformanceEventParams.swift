import Foundation

public struct PerformanceEventParams {
    public let lineItemId: String
    public let creativeId: String
    public let adUnit: String
    public let productSku: String
    public let payload: String
    public let keyword: String?
    public let userId: String?

    public init(
        lineItemId: String,
        creativeId: String,
        adUnit: String,
        productSku: String,
        payload: String,
        keyword: String? = nil,
        userId: String? = nil
    ) {
        self.lineItemId = lineItemId
        self.creativeId = creativeId
        self.adUnit = adUnit
        self.productSku = productSku
        self.payload = payload
        self.keyword = keyword
        self.userId = userId
    }
}

