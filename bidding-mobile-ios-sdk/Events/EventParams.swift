import Foundation

public struct EventParams {
    public let userId: String?
    public let lineItemIds: String?
    public let productList: String?
    public let categoryId: String?
    public let keyword: String?
    public let loyaltyCard: String?
    public let transactionId: String?
    public let totalRowCount: Int?

    public init(
        userId: String? = nil,
        lineItemIds: String? = nil,
        productList: String? = nil,
        categoryId: String? = nil,
        keyword: String? = nil,
        loyaltyCard: String? = nil,
        transactionId: String? = nil,
        totalRowCount: Int? = nil
    ) {
        self.userId = userId
        self.lineItemIds = lineItemIds
        self.productList = productList
        self.categoryId = categoryId
        self.keyword = keyword
        self.loyaltyCard = loyaltyCard
        self.transactionId = transactionId
        self.totalRowCount = totalRowCount
    }
}

