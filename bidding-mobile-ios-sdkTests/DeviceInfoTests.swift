import XCTest
@testable import bidding_mobile_ios_sdk

// swiftlint:disable identifier_name
// 'os' is a standard variable name in device info contexts

final class DeviceInfoTests: XCTestCase {

    func testGetDeviceId_ShouldReturnNonEmptyString() throws {
        // When
        let deviceId = DeviceInfo.shared.getDeviceId()

        // Then
        XCTAssertFalse(deviceId.isEmpty)
    }

    func testGetDeviceId_CalledMultipleTimes_ShouldReturnSameValue() throws {
        // When
        let deviceId1 = DeviceInfo.shared.getDeviceId()
        let deviceId2 = DeviceInfo.shared.getDeviceId()

        // Then
        XCTAssertEqual(deviceId1, deviceId2)
    }

    func testGetAppName_ShouldReturnNonEmptyString() throws {
        // When
        let appName = DeviceInfo.shared.getAppName()

        // Then
        XCTAssertFalse(appName.isEmpty)
    }

    func testGetOs_ShouldReturnIOS() throws {
        // When
        let os = DeviceInfo.shared.getOs()

        // Then
        XCTAssertEqual(os, "iOS")
    }

    func testGetLanguage_ShouldReturnValidFormat() throws {
        // When
        let language = DeviceInfo.shared.getLanguage()

        // Then
        XCTAssertFalse(language.isEmpty)
        XCTAssertTrue(language.contains("-"))
    }

    func testGetBrowser_ShouldReturnNil() throws {
        // When
        let browser = DeviceInfo.shared.getBrowser()

        // Then
        XCTAssertNil(browser)
    }
}

