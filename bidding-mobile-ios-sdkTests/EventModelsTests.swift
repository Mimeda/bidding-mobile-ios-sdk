import XCTest
@testable import bidding_mobile_ios_sdk

final class EventModelsTests: XCTestCase {
    
    func testEventName_Values_ShouldBeCorrect() throws {
        XCTAssertEqual(EventName.home.value, "home")
        XCTAssertEqual(EventName.listing.value, "listing")
        XCTAssertEqual(EventName.search.value, "search")
        XCTAssertEqual(EventName.pdp.value, "pdp")
        XCTAssertEqual(EventName.cart.value, "cart")
        XCTAssertEqual(EventName.purchase.value, "purchase")
    }
    
    func testEventParameter_Values_ShouldBeCorrect() throws {
        XCTAssertEqual(EventParameter.view.value, "view")
        XCTAssertEqual(EventParameter.addToCart.value, "addtocart")
        XCTAssertEqual(EventParameter.addToFavorites.value, "addtofavorites")
        XCTAssertEqual(EventParameter.success.value, "success")
    }
    
    func testEventParams_DefaultValues_ShouldBeNil() throws {
        // Given & When
        let params = EventParams()
        
        // Then
        XCTAssertNil(params.userId)
        XCTAssertNil(params.lineItemIds)
        XCTAssertNil(params.productList)
        XCTAssertNil(params.categoryId)
        XCTAssertNil(params.keyword)
        XCTAssertNil(params.loyaltyCard)
        XCTAssertNil(params.transactionId)
        XCTAssertNil(params.totalRowCount)
    }
    
    func testEventParams_WithValues_ShouldStoreCorrectly() throws {
        // Given & When
        let params = EventParams(
            userId: "user123",
            lineItemIds: "li1,li2",
            productList: "p1,p2,p3",
            categoryId: "cat1",
            keyword: "test",
            loyaltyCard: "lc123",
            transactionId: "trans456",
            totalRowCount: 10
        )
        
        // Then
        XCTAssertEqual(params.userId, "user123")
        XCTAssertEqual(params.lineItemIds, "li1,li2")
        XCTAssertEqual(params.productList, "p1,p2,p3")
        XCTAssertEqual(params.categoryId, "cat1")
        XCTAssertEqual(params.keyword, "test")
        XCTAssertEqual(params.loyaltyCard, "lc123")
        XCTAssertEqual(params.transactionId, "trans456")
        XCTAssertEqual(params.totalRowCount, 10)
    }
    
    func testPerformanceEventParams_WithRequiredValues_ShouldStoreCorrectly() throws {
        // Given & When
        let params = PerformanceEventParams(
            lineItemId: "li123",
            creativeId: "c456",
            adUnit: "banner",
            productSku: "sku789",
            payload: "test-payload"
        )
        
        // Then
        XCTAssertEqual(params.lineItemId, "li123")
        XCTAssertEqual(params.creativeId, "c456")
        XCTAssertEqual(params.adUnit, "banner")
        XCTAssertEqual(params.productSku, "sku789")
        XCTAssertEqual(params.payload, "test-payload")
        XCTAssertNil(params.keyword)
        XCTAssertNil(params.userId)
    }
    
    func testPerformanceEventParams_WithAllValues_ShouldStoreCorrectly() throws {
        // Given & When
        let params = PerformanceEventParams(
            lineItemId: "li123",
            creativeId: "c456",
            adUnit: "banner",
            productSku: "sku789",
            payload: "test-payload",
            keyword: "search-term",
            userId: "user123"
        )
        
        // Then
        XCTAssertEqual(params.lineItemId, "li123")
        XCTAssertEqual(params.creativeId, "c456")
        XCTAssertEqual(params.adUnit, "banner")
        XCTAssertEqual(params.productSku, "sku789")
        XCTAssertEqual(params.payload, "test-payload")
        XCTAssertEqual(params.keyword, "search-term")
        XCTAssertEqual(params.userId, "user123")
    }
    
    // MARK: - PerformanceEventType Tests
    
    func testPerformanceEventType_Endpoints_ShouldBeCorrect() throws {
        XCTAssertEqual(PerformanceEventType.impression.endpoint, "impressions")
        XCTAssertEqual(PerformanceEventType.click.endpoint, "clicks")
    }
}

