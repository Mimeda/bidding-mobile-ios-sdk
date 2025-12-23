import Foundation

internal final class EventTracker {
    
    private enum Constants {
        static let sessionDurationMs = SDKConfig.sessionDurationMs
        static let keySessionId = "session_id"
        static let keySessionTimestamp = "session_timestamp"
        static let keyAnonymousId = "anonymous_id"
        static let shutdownTimeoutSeconds: TimeInterval = 5.0
    }
    
    private let apiService: ApiService
    private let serialQueue: DispatchQueue
    private var isShutdown = false
    private let lock = NSLock()

    /// - Parameter apiService: API service
    init(apiService: ApiService) {
        self.apiService = apiService
        self.serialQueue = DispatchQueue(label: "com.mimeda.sdk.eventtracker", qos: .utility)
    }
    
    /// Session ID creator
    private func getOrCreateSessionId() -> String {
        let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        let savedSessionId = SecureStorage.getString(Constants.keySessionId)
        let savedTimestamp = SecureStorage.getLong(Constants.keySessionTimestamp, defaultValue: 0)
        
        if savedSessionId == nil || (currentTime - savedTimestamp) > Int64(Constants.sessionDurationMs) {
            let newSessionId = UUID().uuidString
            SecureStorage.setString(Constants.keySessionId, value: newSessionId)
            SecureStorage.setLong(Constants.keySessionTimestamp, value: currentTime)
            return newSessionId
        } else {
            return savedSessionId!
        }
    }
    
    /// Anonymous ID creator
    private func getOrCreateAnonymousId() -> String {
        if let savedAnonymousId = SecureStorage.getString(Constants.keyAnonymousId) {
            return savedAnonymousId
        } else {
            let newAnonymousId = UUID().uuidString
            SecureStorage.setString(Constants.keyAnonymousId, value: newAnonymousId)
            return newAnonymousId
        }
    }
    
    /// Event track
    func track(
        eventName: EventName,
        eventParameter: EventParameter,
        params: EventParams,
        eventType: EventType
    ) {
        lock.lock()
        let shutdown = isShutdown
        lock.unlock()
        
        guard !shutdown else {
            Logger.e("EventTracker is shutdown, cannot track event")
            return
        }
        
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            
            let sessionId = self.getOrCreateSessionId()
            let anonymousId = self.getOrCreateAnonymousId()
            
            self.apiService.trackEvent(
                eventName: eventName,
                eventParameter: eventParameter,
                params: params,
                eventType: eventType,
                appName: DeviceInfo.shared.getAppName(),
                deviceId: DeviceInfo.shared.getDeviceId(),
                os: DeviceInfo.shared.getOs(),
                language: DeviceInfo.shared.getLanguage(),
                sessionId: sessionId,
                anonymousId: anonymousId
            )
        }
    }
    
    /// - Parameters:
    ///   - eventType: Performance event type
    ///   - params: Performance event params
    func trackPerformance(
        eventType: PerformanceEventType,
        params: PerformanceEventParams
    ) {
        lock.lock()
        let shutdown = isShutdown
        lock.unlock()
        
        guard !shutdown else {
            Logger.e("EventTracker is shutdown, cannot track performance event")
            return
        }
        
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            
            let sessionId = self.getOrCreateSessionId()
            let anonymousId = self.getOrCreateAnonymousId()
            
            self.apiService.trackPerformanceEvent(
                eventType: eventType,
                params: params,
                appName: DeviceInfo.shared.getAppName(),
                deviceId: DeviceInfo.shared.getDeviceId(),
                os: DeviceInfo.shared.getOs(),
                language: DeviceInfo.shared.getLanguage(),
                sessionId: sessionId,
                anonymousId: anonymousId
            )
        }
    }
    
    /// EventTracker shutdown
    func shutdown() {
        lock.lock()
        isShutdown = true
        lock.unlock()
        
        let semaphore = DispatchSemaphore(value: 0)
        
        serialQueue.async {
            semaphore.signal()
        }
        
        let result = semaphore.wait(timeout: .now() + Constants.shutdownTimeoutSeconds)
        
        if result == .timedOut {
            Logger.e("EventTracker shutdown timed out")
        } else {
            Logger.i("EventTracker shutdown completed")
        }
    }
}
