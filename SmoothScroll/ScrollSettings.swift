import Foundation
import Observation

private let isEnabledKey = "scroll.isEnabled"
private let pixelsPerWheelStepKey = "scroll.pixelsPerWheelStep"
private let interpolationKey = "scroll.interpolation"
private let reverseVerticalKey = "scroll.reverseVertical"
private let reverseHorizontalKey = "scroll.reverseHorizontal"

@MainActor
@Observable
final class ScrollSettings {
    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: isEnabledKey) }
    }

    var pixelsPerWheelStep: Double {
        didSet { defaults.set(pixelsPerWheelStep, forKey: pixelsPerWheelStepKey) }
    }

    var interpolation: Double {
        didSet { defaults.set(interpolation, forKey: interpolationKey) }
    }

    var reverseVertical: Bool {
        didSet { defaults.set(reverseVertical, forKey: reverseVerticalKey) }
    }

    var reverseHorizontal: Bool {
        didSet { defaults.set(reverseHorizontal, forKey: reverseHorizontalKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.object(forKey: isEnabledKey) as? Bool ?? ScrollConfiguration.default.isEnabled
        pixelsPerWheelStep = (defaults.object(forKey: pixelsPerWheelStepKey) as? Double ?? ScrollConfiguration.default.pixelsPerWheelStep)
            .clamped(to: ScrollConfiguration.pixelsPerWheelStepRange)
        interpolation = (defaults.object(forKey: interpolationKey) as? Double ?? ScrollConfiguration.default.interpolation)
            .clamped(to: ScrollConfiguration.interpolationRange)
        reverseVertical = defaults.object(forKey: reverseVerticalKey) as? Bool ?? ScrollConfiguration.default.reverseVertical
        reverseHorizontal = defaults.object(forKey: reverseHorizontalKey) as? Bool ?? ScrollConfiguration.default.reverseHorizontal
    }

    var configuration: ScrollConfiguration {
        ScrollConfiguration(
            isEnabled: isEnabled,
            pixelsPerWheelStep: pixelsPerWheelStep,
            interpolation: interpolation,
            deadZone: ScrollConfiguration.default.deadZone,
            maximumFrameDelta: ScrollConfiguration.default.maximumFrameDelta,
            reverseVertical: reverseVertical,
            reverseHorizontal: reverseHorizontal
        )
    }
}
