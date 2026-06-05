import SwiftUI

struct StatusSectionView: View {
    @Bindable var controller: SmoothScrollController

    var body: some View {
        Section("Status") {
            LabeledContent("Smooth scrolling", value: controller.settings.isEnabled ? "Enabled" : "Disabled")
            LabeledContent("Event tap", value: controller.isRunning ? "Running" : "Stopped")
            LabeledContent("Permissions", value: controller.permissionState.statusText)

            if let lastError = controller.lastError {
                Text(lastError)
                    .foregroundStyle(.red)
            }

            Button("Request Permissions", action: controller.requestPermissions)
        }
    }
}
