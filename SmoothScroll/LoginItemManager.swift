import ServiceManagement

/// Thin wrapper around `SMAppService.mainApp` for launch-at-login control.
///
/// `SMAppService` (macOS 13+) registers the main app bundle itself as a login
/// item, so no separate helper bundle or `launchd` plist is required.
enum LoginItemManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }
    }
}
