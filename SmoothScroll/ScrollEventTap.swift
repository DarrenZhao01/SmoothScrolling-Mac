import CoreGraphics
import Foundation

/// Wraps a Quartz scroll-wheel event tap.
///
/// The tap is serviced on a dedicated high-priority thread rather than the main
/// run loop. A `.cgSessionEventTap` processes events serially and blocks the
/// stream until the callback returns, so servicing it on a busy main loop stalls
/// every event queued behind a scroll (including mouse moves). The callback here
/// only buffers the delta and returns immediately.
final class ScrollEventTap {
    private let engine: SmoothScrollingEngine
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var thread: Thread?
    private let stateLock = NSLock()
    private var threadRunLoop: CFRunLoop?

    init(engine: SmoothScrollingEngine) {
        self.engine = engine
    }

    deinit {
        stop()
    }

    var isRunning: Bool {
        guard let eventTap else {
            return false
        }

        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    func start() throws {
        if eventTap == nil {
            try createEventTap()
        }

        guard let eventTap, let runLoopSource else {
            throw ScrollEventTapError.creationFailed
        }

        guard thread == nil else {
            CGEvent.tapEnable(tap: eventTap, enable: true)
            return
        }

        let thread = Thread { [weak self] in
            self?.runTapLoop(source: runLoopSource, tap: eventTap)
        }
        thread.name = "com.smooth.ScrollEventTap"
        thread.qualityOfService = .userInteractive
        self.thread = thread
        thread.start()
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        let runLoop = stateLock.withLock { threadRunLoop }
        if let runLoop {
            CFRunLoopStop(runLoop)
        }

        stateLock.withLock { threadRunLoop = nil }
        thread = nil
    }

    func refreshAfterSystemDisabledTap() {
        guard let eventTap else {
            return
        }

        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
}

private extension ScrollEventTap {
    func createEventTap() throws {
        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: ScrollEventTap.callback,
            userInfo: userInfo
        ) else {
            throw ScrollEventTapError.creationFailed
        }

        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    }

    func runTapLoop(source: CFRunLoopSource, tap: CFMachPort) {
        let runLoop = CFRunLoopGetCurrent()
        stateLock.withLock { threadRunLoop = runLoop }

        CFRunLoopAddSource(runLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        CFRunLoopRun()

        CFRunLoopRemoveSource(runLoop, source, .commonModes)
    }

    static let callback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let tap = Unmanaged<ScrollEventTap>.fromOpaque(userInfo).takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            tap.refreshAfterSystemDisabledTap()
            return Unmanaged.passUnretained(event)
        }

        guard type == .scrollWheel else {
            return Unmanaged.passUnretained(event)
        }

        if tap.engine.enqueueWheelEvent(event) {
            return nil
        }

        return Unmanaged.passUnretained(event)
    }
}
