import Foundation

/// Event and performance tracking
public final class MimedaSDK {
    
    public static let shared = MimedaSDK()
    
    private var isInitialized = false
    private var eventTracker: EventTracker?
    private weak var errorCallback: MimedaSDKErrorCallback?
    private let lock = NSLock()
    
    private init() {}
    
    /// - Parameters:
    ///   - apiKey: API key
    ///   - environment: default: production
    ///   - errorCallback: Error callback
    public func initialize(
        apiKey: String,
        environment: SDKEnvironment = .production,
        errorCallback: MimedaSDKErrorCallback? = nil
    ) {
        lock.lock()
        defer { lock.unlock() }
        
        if isInitialized {
            Logger.i("MimedaSDK is already initialized")
            return
        }
        
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            Logger.e("API key is required but was not provided")
            return
        }
        
        let appPackageName = Bundle.main.bundleIdentifier ?? ""
        guard !appPackageName.isEmpty else {
            Logger.e("Package name is required but could not be retrieved from bundle")
            return
        }
        
        self.errorCallback = errorCallback
        
        let client = ApiClient.createClient(apiKey: apiKey, packageName: appPackageName)
        let apiService = ApiService(client: client, environment: environment, errorCallback: errorCallback)
        eventTracker = EventTracker(apiService: apiService)
        
        isInitialized = true
        Logger.s("MimedaSDK initialized successfully. Package: \(appPackageName), Environment: \(environment)")
    }
   
    /// - Parameters:
    ///   - eventName: Event name
    ///   - eventParameter: Event params
    ///   - params: Optional params
    public func trackEvent(
        eventName: EventName,
        eventParameter: EventParameter,
        params: EventParams = EventParams()
    ) {
        lock.lock()
        let initialized = isInitialized
        let tracker = eventTracker
        lock.unlock()
        
        guard initialized else {
            Logger.e("SDK is not initialized. Call initialize() before tracking events")
            return
        }
        
        guard let tracker = tracker else {
            Logger.e("EventTracker is not available")
            return
        }
        
        tracker.track(
            eventName: eventName,
            eventParameter: eventParameter,
            params: params,
            eventType: .event
        )
    }
    
    /// - Parameter params: Performance event params
    public func trackPerformanceImpression(params: PerformanceEventParams) {
        lock.lock()
        let initialized = isInitialized
        let tracker = eventTracker
        lock.unlock()
        
        guard initialized else {
            Logger.e("SDK is not initialized. Call initialize() before tracking events")
            return
        }
        
        guard let tracker = tracker else {
            Logger.e("EventTracker is not available")
            return
        }
        
        tracker.trackPerformance(
            eventType: .impression,
            params: params
        )
    }
    
    /// - Parameter params: Performance event params
    public func trackPerformanceClick(params: PerformanceEventParams) {
        lock.lock()
        let initialized = isInitialized
        let tracker = eventTracker
        lock.unlock()
        
        guard initialized else {
            Logger.e("SDK is not initialized. Call initialize() before tracking events")
            return
        }
        
        guard let tracker = tracker else {
            Logger.e("EventTracker is not available")
            return
        }
        
        tracker.trackPerformance(
            eventType: .click,
            params: params
        )
    }

    public func isSDKInitialized() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isInitialized
    }
    
    public func shutdown() {
        lock.lock()
        defer { lock.unlock() }
        
        eventTracker?.shutdown()
        eventTracker = nil
        isInitialized = false
        Logger.i("MimedaSDK shutdown completed")
    }
}
