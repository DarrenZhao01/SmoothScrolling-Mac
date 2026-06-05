import SwiftUI

struct StatusMenuView: View {
    @Bindable var controller: SmoothScrollController

    var body: some View {
        Button(controller.settings.isEnabled ? "Disable Smooth Scrolling" : "Enable Smooth Scrolling", action: controller.toggleEnabled)

        Divider()

        Text(controller.permissionState.statusText)

        Button("Request Permissions", action: controller.requestPermissions)
        Button("Refresh Permissions", action: controller.refreshPermissions)

        Divider()

        Toggle("Launch at Login", isOn: $controller.launchAtLogin)
            .onChange(of: controller.launchAtLogin, controller.applyLaunchAtLogin)

        Divider()

        Button("Quit SmoothScroll", action: controller.quit)
    }
}
