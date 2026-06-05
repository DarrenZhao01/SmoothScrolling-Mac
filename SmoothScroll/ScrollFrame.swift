import CoreGraphics
import Foundation

struct ScrollFrame {
    var fixedDeltaX: Double
    var fixedDeltaY: Double
    var pointDeltaX: Int
    var pointDeltaY: Int
    var location: CGPoint
    var flags: CGEventFlags
}
