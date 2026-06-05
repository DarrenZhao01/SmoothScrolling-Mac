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

        Button("Quit SmoothScroll", action: controller.quit)
    }
}
