import AppKit
import CoreGraphics
import Foundation
import QuartzCore

/// Turns discrete mouse-wheel notches into a high-frequency stream of small
/// pixel deltas driven by a display link.
///
/// Each notch adds distance to a momentum buffer. Every display frame drains a
/// fraction of that buffer, scaled by the real frame duration so the feel is
/// identical at 60 Hz or 120 Hz. Output uses continuous pixel deltas without a
/// scroll phase, so scroll views clamp at their boundaries instead of
/// rubber-banding past them.
final class SmoothScrollingEngine {
    private static let syntheticEventMarker: Int64 = 0x53534D4F4F5448

    private let lock = NSLock()
    private var displayLink: CADisplayLink?
    private var configuration = ScrollConfiguration.default
    private var remainingX = 0.0
    private var remainingY = 0.0
    private var pointRemainderX = 0.0
    private var pointRemainderY = 0.0
    private var lastLocation = CGPoint.zero
    private var lastFlags = CGEventFlags()

    deinit {
        displayLink?.invalidate()
    }

    func updateConfiguration(_ configuration: ScrollConfiguration) {
        lock.withLock {
            self.configuration = configuration
            if !configuration.isEnabled {
                resetLocked()
            }
        }

        if !configuration.isEnabled {
            stopDisplayLinkOnMain()
        }
    }

    func enqueueWheelEvent(_ event: CGEvent) -> Bool {
        guard !Self.isSynthetic(event), isDiscreteWheel(event) else {
            return false
        }

        let started: Bool = lock.withLock {
            guard configuration.isEnabled else {
                return false
            }

            let delta = scaledDelta(from: event, configuration: configuration)
            guard abs(delta.x) > 0 || abs(delta.y) > 0 else {
                return false
            }

            remainingX += delta.x
            remainingY += delta.y
            lastLocation = event.location
            lastFlags = event.flags
            return true
        }

        if started {
            ensureDisplayLinkRunning()
        }

        return started
    }

    static func isSynthetic(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == syntheticEventMarker
    }
}

private extension SmoothScrollingEngine {
    func isDiscreteWheel(_ event: CGEvent) -> Bool {
        if event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0 {
            return false
        }

        if event.getIntegerValueField(.scrollWheelEventScrollPhase) != 0 {
            return false
        }

        if event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0 {
            return false
        }

        return true
    }

    func scaledDelta(from event: CGEvent, configuration: ScrollConfiguration) -> CGPoint {
        var y = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis1)) * configuration.pixelsPerWheelStep
        var x = Double(event.getIntegerValueField(.scrollWheelEventDeltaAxis2)) * configuration.pixelsPerWheelStep

        if event.flags.contains(.maskShift), x == 0, y != 0 {
            x = y
            y = 0
        }

        if configuration.reverseVertical {
            y *= -1
        }

        if configuration.reverseHorizontal {
            x *= -1
        }

        return CGPoint(x: x, y: y)
    }

    // MARK: Display link lifecycle (main thread only)

    func ensureDisplayLinkRunning() {
        if Thread.isMainThread {
            startDisplayLinkOnMain()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.startDisplayLinkOnMain()
            }
        }
    }

    func startDisplayLinkOnMain() {
        if displayLink == nil, let screen = NSScreen.main {
            let link = screen.displayLink(target: self, selector: #selector(displayLinkDidFire(_:)))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        displayLink?.isPaused = false
    }

    func stopDisplayLinkOnMain() {
        if Thread.isMainThread {
            displayLink?.isPaused = true
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.displayLink?.isPaused = true
            }
        }
    }

    @objc func displayLinkDidFire(_ link: CADisplayLink) {
        let interval = link.targetTimestamp - link.timestamp
        let frameDuration = min(max(interval, 1.0 / 240.0), 1.0 / 30.0)

        let frame = lock.withLock {
            nextFrameLocked(frameDuration: frameDuration)
        }

        guard let frame else {
            displayLink?.isPaused = true
            return
        }

        postSyntheticScroll(frame)
    }

    func nextFrameLocked(frameDuration: Double) -> ScrollFrame? {
        let magnitude = max(abs(remainingX), abs(remainingY))
        guard magnitude > configuration.deadZone else {
            resetLocked()
            return nil
        }

        // Frame-rate-independent decay: `interpolation` is the fraction consumed
        // per 1/60 s, rescaled to the real frame duration.
        let factor = 1 - pow(1 - configuration.interpolation, frameDuration * 60)

        var stepX = clampedFrameDelta(remainingX * factor, limit: configuration.maximumFrameDelta)
        var stepY = clampedFrameDelta(remainingY * factor, limit: configuration.maximumFrameDelta)
        remainingX -= stepX
        remainingY -= stepY

        // Integer point deltas carry their sub-pixel remainder so slow scrolls
        // stay smooth instead of quantizing to whole pixels each frame.
        let desiredPointX = stepX + pointRemainderX
        let desiredPointY = stepY + pointRemainderY
        let pointDeltaX = desiredPointX.rounded(.toNearestOrAwayFromZero)
        let pointDeltaY = desiredPointY.rounded(.toNearestOrAwayFromZero)
        pointRemainderX = desiredPointX - pointDeltaX
        pointRemainderY = desiredPointY - pointDeltaY

        return ScrollFrame(
            fixedDeltaX: stepX,
            fixedDeltaY: stepY,
            pointDeltaX: Int(pointDeltaX),
            pointDeltaY: Int(pointDeltaY),
            location: lastLocation,
            flags: lastFlags
        )
    }

    func clampedFrameDelta(_ value: Double, limit: Double) -> Double {
        min(max(value, -limit), limit)
    }

    func resetLocked() {
        remainingX = 0
        remainingY = 0
        pointRemainderX = 0
        pointRemainderY = 0
    }

    func postSyntheticScroll(_ frame: ScrollFrame) {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(frame.pointDeltaY),
            wheel2: Int32(frame.pointDeltaX),
            wheel3: 0
        ) else {
            return
        }

        // Do not set event.location: posting a scroll event with an explicit
        // location warps the cursor to that point every frame, freezing the
        // user's pointer for the whole animation. Leaving it unset uses the
        // current cursor position, which is also the correct scroll target.
        event.flags = frame.flags
        event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticEventMarker)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: Int64(frame.pointDeltaY))
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: Int64(frame.pointDeltaX))
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: frame.fixedDeltaY)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: frame.fixedDeltaX)
        event.post(tap: .cghidEventTap)
    }
}
