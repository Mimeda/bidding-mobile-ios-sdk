import Foundation
import os.log

internal struct Logger {
    private static let subsystem = "com.mimeda.sdk"
    private static let category = "MimedaSDK"
    private static let osLog = OSLog(subsystem: subsystem, category: category)

    private static let lock = NSLock()
    private static var _isDebugEnabled: Bool?

    static var isDebugEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }

        if let enabled = _isDebugEnabled {
            return enabled
        }
        return SDKConfig.debugLogging
    }

    /// Set debug logging enabled/disabled at runtime
    /// - Parameter enabled: true to enable debug logging, false to disable
    static func setDebugLogging(_ enabled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        _isDebugEnabled = enabled
    }

    static func i(_ message: String) {
        guard isDebugEnabled else { return }
        os_log("[INFO] %{public}@", log: osLog, type: .info, message)
    }

    /// - Parameters:
    ///   - message: Log message
    ///   - error: optional hata
    static func e(_ message: String, _ error: Error? = nil) {
        guard isDebugEnabled else { return }
        if let error = error {
            os_log("[ERROR] %{public}@ - %{public}@", log: osLog, type: .error, message, error.localizedDescription)
        } else {
            os_log("[ERROR] %{public}@", log: osLog, type: .error, message)
        }
    }

    /// - Parameter message: Log message
    static func s(_ message: String) {
        guard isDebugEnabled else { return }
        os_log("[SUCCESS] %{public}@", log: osLog, type: .info, message)
    }

    /// - Parameter message: Log message
    static func d(_ message: String) {
        guard isDebugEnabled else { return }
        os_log("[DEBUG] %{public}@", log: osLog, type: .debug, message)
    }
}

