import SwiftUI

struct ScrollingSectionView: View {
    @Bindable var controller: SmoothScrollController

    var body: some View {
        Section("Scrolling") {
            Toggle("Enable smooth scrolling", isOn: $controller.settings.isEnabled)
                .onChange(of: controller.settings.isEnabled, controller.applySettings)

            Slider(value: $controller.settings.pixelsPerWheelStep, in: ScrollConfiguration.pixelsPerWheelStepRange, step: 5) {
                Text("Pixels per wheel step")
            } minimumValueLabel: {
                Text("20")
            } maximumValueLabel: {
                Text("240")
            }
            .onChange(of: controller.settings.pixelsPerWheelStep, controller.applySettings)

            LabeledContent("Wheel step", value: controller.settings.pixelsPerWheelStep, format: .number.precision(.fractionLength(0)))

            Slider(value: $controller.settings.interpolation, in: ScrollConfiguration.interpolationRange, step: 0.01) {
                Text("Smoothing")
            } minimumValueLabel: {
                Text("Floaty")
            } maximumValueLabel: {
                Text("Snappy")
            }
            .onChange(of: controller.settings.interpolation, controller.applySettings)

            LabeledContent("Smoothing", value: controller.settings.interpolation, format: .number.precision(.fractionLength(2)))

            Toggle("Reverse vertical scrolling", isOn: $controller.settings.reverseVertical)
                .onChange(of: controller.settings.reverseVertical, controller.applySettings)

            Toggle("Reverse horizontal scrolling", isOn: $controller.settings.reverseHorizontal)
                .onChange(of: controller.settings.reverseHorizontal, controller.applySettings)
        }
    }
}
