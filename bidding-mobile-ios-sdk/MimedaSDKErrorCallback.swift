import Foundation

public protocol MimedaSDKErrorCallback: AnyObject {

    func onEventTrackingFailed(
        eventName: EventName,
        eventParameter: EventParameter,
        error: Error
    )

    func onPerformanceEventTrackingFailed(
        eventType: PerformanceEventType,
        error: Error
    )

    func onValidationFailed(
        eventName: EventName?,
        errors: [String]
    )
}

