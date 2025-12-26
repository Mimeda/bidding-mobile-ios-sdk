import Foundation
#if canImport(UIKit)
import UIKit
#endif

internal final class DeviceInfo {

    static let shared = DeviceInfo()

    private var _deviceId: String?
    private var _appName: String?
    private let lock = NSLock()

    private init() {
        initialize()
    }

    private func initialize() {
        lock.lock()
        defer { lock.unlock() }

        #if canImport(UIKit)
        _deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        _deviceId = UUID().uuidString
        #endif

        _appName = Bundle.main.bundleIdentifier ?? "unknown"
    }

    func getDeviceId() -> String {
        lock.lock()
        defer { lock.unlock() }
        return _deviceId ?? UUID().uuidString
    }

    func getAppName() -> String {
        lock.lock()
        defer { lock.unlock() }
        return _appName ?? "unknown"
    }

    func getOs() -> String {
        return "iOS"
    }

    func getLanguage() -> String {
        let locale = Locale.current
        let language = locale.language.languageCode?.identifier ?? "en"
        let region = locale.region?.identifier ?? "US"
        return "\(language)-\(region)"
    }

    func getBrowser() -> String? {
        return nil
    }
}
