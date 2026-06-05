import ApplicationServices
import Foundation

enum PermissionManager {
    static func currentState() -> PermissionState {
        PermissionState(isAccessibilityTrusted: AXIsProcessTrusted())
    }

    @discardableResult
    static func requestAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
