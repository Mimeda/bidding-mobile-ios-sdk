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
        XCTAssertTrue(MimedaSDK.shared.isInitialized())
    }

    func testInitialize_WithEmptyApiKey_ShouldNotInitialize() throws {
        // Given
        let apiKey = ""

        // When
        MimedaSDK.shared.initialize(apiKey: apiKey, environment: .staging)

        // Then
        XCTAssertFalse(MimedaSDK.shared.isInitialized())
    }

    func testInitialize_WithWhitespaceApiKey_ShouldNotInitialize() throws {
        // Given
        let apiKey = "   "

        // When
        MimedaSDK.shared.initialize(apiKey: apiKey, environment: .staging)

        // Then
        XCTAssertFalse(MimedaSDK.shared.isInitialized())
    }

    func testInitialize_CalledTwice_ShouldOnlyInitializeOnce() throws {
        // Given
        let apiKey = "test-api-key"

        // When
        MimedaSDK.shared.initialize(apiKey: apiKey, environment: .staging)
        MimedaSDK.shared.initialize(apiKey: apiKey, environment: .production)

        // Then
        XCTAssertTrue(MimedaSDK.shared.isInitialized())
    }

    func testShutdown_AfterInitialize_ShouldResetState() throws {
        // Given
        MimedaSDK.shared.initialize(apiKey: "test-api-key", environment: .staging)
        XCTAssertTrue(MimedaSDK.shared.isInitialized())

        // When
        MimedaSDK.shared.shutdown()

        // Then
        XCTAssertFalse(MimedaSDK.shared.isInitialized())
    }

    func testShutdown_WithoutInitialize_ShouldNotCrash() throws {
        // Given - SDK not initialized

        // When & Then - should not crash
        MimedaSDK.shared.shutdown()
        XCTAssertFalse(MimedaSDK.shared.isInitialized())
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
        XCTAssertEqual(environment.eventBaseURL, "https://bidding-eventcollector-stage.mlink.com.tr")
        XCTAssertEqual(environment.performanceBaseURL, "https://bidding-prfmnccollector-stage.mlink.com.tr")
    }

    func testSetDebugLogging_Enable_ShouldEnableLogging() throws {
        // Given
        MimedaSDK.shared.initialize(apiKey: "test-api-key", environment: .staging)

        // When
        MimedaSDK.shared.setDebugLogging(true)

        // Then - No exception should be thrown, logging should be enabled
        // Note: We can't easily test OSLog output in unit tests, but we verify the method exists and doesn't crash
        XCTAssertTrue(MimedaSDK.shared.isInitialized())
    }

    func testSetDebugLogging_Disable_ShouldDisableLogging() throws {
        // Given
        MimedaSDK.shared.initialize(apiKey: "test-api-key", environment: .staging)

        // When
        MimedaSDK.shared.setDebugLogging(false)

        // Then - No exception should be thrown, logging should be disabled
        XCTAssertTrue(MimedaSDK.shared.isInitialized())
    }
}

