import XCTest
@testable import bidding_mobile_ios_sdk

final class MimedaSDKTests: XCTestCase {
    
    override func setUpWithError() throws {
        MimedaSDK.shared.shutdown()
    }
    
    override func tearDownWithError() throws {
        MimedaSDK.shared.shutdown()
    }
    
    func testInitialize_WithValidApiKey_ShouldSucceed() throws {
        // Given
        let apiKey = "test-api-key"
        
        // When
        MimedaSDK.shared.initialize(apiKey: apiKey, environment: .staging)
        
        // Then
        XCTAssertTrue(MimedaSDK.shared.isSDKInitialized())
    }
    
    func testInitialize_WithEmptyApiKey_ShouldNotInitialize() throws {
        // Given
        let apiKey = ""
        
        // When
        MimedaSDK.shared.initialize(apiKey: apiKey, environment: .staging)
        
        // Then
        XCTAssertFalse(MimedaSDK.shared.isSDKInitialized())
    }
    
    func testInitialize_WithWhitespaceApiKey_ShouldNotInitialize() throws {
        // Given
        let apiKey = "   "
        
        // When
        MimedaSDK.shared.initialize(apiKey: apiKey, environment: .staging)
        
        // Then
        XCTAssertFalse(MimedaSDK.shared.isSDKInitialized())
    }
    
    func testInitialize_CalledTwice_ShouldOnlyInitializeOnce() throws {
        // Given
        let apiKey = "test-api-key"
        
        // When
        MimedaSDK.shared.initialize(apiKey: apiKey, environment: .staging)
        MimedaSDK.shared.initialize(apiKey: apiKey, environment: .production)
        
        // Then
        XCTAssertTrue(MimedaSDK.shared.isSDKInitialized())
    }

    func testShutdown_AfterInitialize_ShouldResetState() throws {
        // Given
        MimedaSDK.shared.initialize(apiKey: "test-api-key", environment: .staging)
        XCTAssertTrue(MimedaSDK.shared.isSDKInitialized())
        
        // When
        MimedaSDK.shared.shutdown()
        
        // Then
        XCTAssertFalse(MimedaSDK.shared.isSDKInitialized())
    }
    
    func testShutdown_WithoutInitialize_ShouldNotCrash() throws {
        // Given - SDK not initialized
        
        // When & Then - should not crash
        MimedaSDK.shared.shutdown()
        XCTAssertFalse(MimedaSDK.shared.isSDKInitialized())
    }

    func testEnvironment_Production_ShouldHaveCorrectURLs() throws {
        // Given
        let environment = SDKEnvironment.production
        
        // Then
        XCTAssertEqual(environment.eventBaseURL, "https://event.mlink.com.tr")
        XCTAssertEqual(environment.performanceBaseURL, "https://performance.mlink.com.tr")
    }
    
    func testEnvironment_Staging_ShouldHaveCorrectURLs() throws {
        // Given
        let environment = SDKEnvironment.staging
        
        // Then
        XCTAssertEqual(environment.eventBaseURL, "https://bidding-eventcollector-stage.azurewebsites.net")
        XCTAssertEqual(environment.performanceBaseURL, "https://bidding-prfmnccollector-stage.azurewebsites.net")
    }
}

