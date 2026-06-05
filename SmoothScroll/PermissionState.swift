import Foundation

struct PermissionState: Equatable {
    var isAccessibilityTrusted: Bool

    var canStartEventTap: Bool {
        isAccessibilityTrusted
    }

    var statusText: String {
        if isAccessibilityTrusted {
            "Ready"
        } else {
            "Accessibility access is required. Grant it in System Settings > Privacy & Security > Accessibility."
        }
    }
}
