import Foundation

public final class MimedaSDK {
    
    public static let shared = MimedaSDK()
    
    private var initialized = false
    private var eventTracker: EventTracker?
    private weak var errorCallback: MimedaSDKErrorCallback?
    private let lock = NSLock()
    
    private init() {}
    
    public func initialize(
        apiKey: String,
        environment: SDKEnvironment = .production,
        errorCallback: MimedaSDKErrorCallback? = nil
    ) {
        lock.lock()
        defer { lock.unlock() }
        
        if initialized {
            Logger.i("MimedaSDK is already initialized")
            return
        }
        
        SecureStorage.checkAndHandleFreshInstall()
        
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
        
        SecureStorage.setString("api_key", value: apiKey)
        
        let client = ApiClient.createClient(apiKey: apiKey, packageName: appPackageName)
        let apiService = ApiService(client: client, environment: environment, errorCallback: errorCallback)
        eventTracker = EventTracker(apiService: apiService)
        
        initialized = true
        Logger.s("MimedaSDK initialized successfully. Package: \(appPackageName), Environment: \(environment)")
    }
   
    public func trackEvent(
        eventName: EventName,
        eventParameter: EventParameter,
        params: EventParams = EventParams()
    ) {
        lock.lock()
        let isInitialized = initialized
        let tracker = eventTracker
        lock.unlock()
        
        guard isInitialized else {
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
    
    public func trackPerformanceImpression(
        params: PerformanceEventParams
    ) {
        lock.lock()
        let isInitialized = initialized
        let tracker = eventTracker
        lock.unlock()
        
        guard isInitialized else {
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
    
    public func trackPerformanceClick(
        params: PerformanceEventParams
    ) {
        lock.lock()
        let isInitialized = initialized
        let tracker = eventTracker
        lock.unlock()
        
        guard isInitialized else {
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

    public func isInitialized() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return initialized
    }
    
    public func setDebugLogging(_ enabled: Bool) {
        Logger.setDebugLogging(enabled)
    }
    
    public func shutdown() {
        lock.lock()
        defer { lock.unlock() }
        
        eventTracker?.shutdown()
        eventTracker = nil
        initialized = false
        
        SecureStorage.remove("api_key")
        
        Logger.i("MimedaSDK shutdown completed")
    }
}
