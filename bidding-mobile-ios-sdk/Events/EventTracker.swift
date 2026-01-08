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

    init(apiService: ApiService) {
        self.apiService = apiService
        self.serialQueue = DispatchQueue(label: "com.mimeda.sdk.eventtracker", qos: .utility)
    }

    private func getOrCreateSessionId() -> String {
        let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        let savedSessionId = SecureStorage.getString(Constants.keySessionId)
        let savedTimestamp = SecureStorage.getLong(Constants.keySessionTimestamp, defaultValue: 0)

        if let sessionId = savedSessionId, (currentTime - savedTimestamp) <= Int64(Constants.sessionDurationMs) {
            return sessionId
        } else {
            let newSessionId = UUID().uuidString
            SecureStorage.setString(Constants.keySessionId, value: newSessionId)
            SecureStorage.setLong(Constants.keySessionTimestamp, value: currentTime)
            return newSessionId
        }
    }

    private func getOrCreateAnonymousId() -> String {
        if let savedAnonymousId = SecureStorage.getString(Constants.keyAnonymousId) {
            return savedAnonymousId
        } else {
            let newAnonymousId = UUID().uuidString
            SecureStorage.setString(Constants.keyAnonymousId, value: newAnonymousId)
            return newAnonymousId
        }
    }

    private func sanitizeParams(_ params: EventParams) -> EventParams {
        return EventParams(
            app: params.app,
            userId: InputValidator.sanitizeUserId(params.userId),
            lineItemIds: InputValidator.sanitizeString(params.lineItemIds),
            productList: InputValidator.sanitizeProductList(params.productList),
            categoryId: InputValidator.sanitizeString(params.categoryId),
            keyword: InputValidator.sanitizeKeyword(params.keyword),
            loyaltyCard: InputValidator.sanitizeString(params.loyaltyCard),
            transactionId: InputValidator.sanitizeString(params.transactionId),
            totalRowCount: params.totalRowCount
        )
    }

    private func sanitizePerformanceParams(_ params: PerformanceEventParams) -> PerformanceEventParams {
        return PerformanceEventParams(
            app: params.app,
            lineItemId: InputValidator.sanitizeString(params.lineItemId),
            creativeId: InputValidator.sanitizeString(params.creativeId),
            adUnit: InputValidator.sanitizeString(params.adUnit),
            productSku: InputValidator.sanitizeString(params.productSku),
            payload: params.payload,
            keyword: InputValidator.sanitizeKeyword(params.keyword),
            userId: InputValidator.sanitizeUserId(params.userId)
        )
    }

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
            
            // TEST: 3 saniye bekle - main thread bloklanma testi
            Logger.i("⏳ Event tracking başladı - 3 saniye bekleniyor...")
            Thread.sleep(forTimeInterval: 3.0)
            Logger.i("✅ 3 saniye bekleme tamamlandı")

            let sanitizedParams = self.sanitizeParams(params)
            let sessionId = self.getOrCreateSessionId()
            let anonymousId = self.getOrCreateAnonymousId()

            self.apiService.trackEvent(
                eventName: eventName,
                eventParameter: eventParameter,
                params: sanitizedParams,
                eventType: eventType,
                deviceId: DeviceInfo.shared.getDeviceId(),
                os: DeviceInfo.shared.getOs(),
                language: DeviceInfo.shared.getLanguage(),
                sessionId: sessionId,
                anonymousId: anonymousId
            )
        }
    }

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
            
            // TEST: 3 saniye bekle - main thread bloklanma testi
            Logger.i("⏳ Performance event tracking başladı - 3 saniye bekleniyor...")
            Thread.sleep(forTimeInterval: 3.0)
            Logger.i("✅ 3 saniye bekleme tamamlandı")

            let sanitizedParams = self.sanitizePerformanceParams(params)
            let sessionId = self.getOrCreateSessionId()
            let anonymousId = self.getOrCreateAnonymousId()

            self.apiService.trackPerformanceEvent(
                eventType: eventType,
                params: sanitizedParams,
                deviceId: DeviceInfo.shared.getDeviceId(),
                os: DeviceInfo.shared.getOs(),
                language: DeviceInfo.shared.getLanguage(),
                sessionId: sessionId,
                anonymousId: anonymousId
            )
        }
    }

    func shutdown() {
        lock.lock()
        isShutdown = true
        lock.unlock()

        if Thread.isMainThread {
            serialQueue.async {
                Logger.i("EventTracker shutdown completed (async)")
            }
            Logger.i("EventTracker shutdown initiated (main thread, non-blocking)")
            return
        }

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

