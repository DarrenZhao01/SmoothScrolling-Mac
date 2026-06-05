import Foundation

struct ScrollConfiguration: Sendable, Equatable {
    var isEnabled: Bool
    var pixelsPerWheelStep: Double
    var interpolation: Double
    var deadZone: Double
    var maximumFrameDelta: Double
    var reverseVertical: Bool
    var reverseHorizontal: Bool

    static let `default` = ScrollConfiguration(
        isEnabled: false,
        pixelsPerWheelStep: 90,
        interpolation: 0.22,
        deadZone: 0.45,
        maximumFrameDelta: 300,
        reverseVertical: false,
        reverseHorizontal: false
    )
}
