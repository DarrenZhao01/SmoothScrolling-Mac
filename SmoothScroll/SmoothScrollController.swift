import AppKit
import Observation

@MainActor
@Observable
final class SmoothScrollController {
    var settings = ScrollSettings()
    var permissionState = PermissionManager.currentState()
    var lastError: String?

    @ObservationIgnored private let engine = SmoothScrollingEngine()
    @ObservationIgnored private lazy var eventTap = ScrollEventTap(engine: engine)

    var isRunning: Bool {
        eventTap.isRunning
    }

    func startIfNeeded() {
        refreshPermissions()
        applySettings()
    }

    func toggleEnabled() {
        settings.isEnabled.toggle()
        applySettings()
    }

    func applySettings() {
        engine.updateConfiguration(settings.configuration)

        guard settings.isEnabled else {
            eventTap.stop()
            lastError = nil
            return
        }

        guard permissionState.canStartEventTap else {
            eventTap.stop()
            lastError = permissionState.statusText
            return
        }

        do {
            try eventTap.start()
            lastError = nil
        } catch {
            lastError = "Could not create the scroll event tap. Check Accessibility permission in System Settings."
        }
    }

    func requestPermissions() {
        PermissionManager.requestAccessibility()
        refreshPermissions()
        applySettings()
    }

    func refreshPermissions() {
        permissionState = PermissionManager.currentState()
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
