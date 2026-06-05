import CoreGraphics
import Foundation

/// Wraps a Quartz scroll-wheel event tap.
///
/// The tap is serviced on a dedicated high-priority thread rather than the main
/// run loop. A `.cgSessionEventTap` processes events serially and blocks the
/// stream until the callback returns, so servicing it on a busy main loop stalls
/// every event queued behind a scroll (including mouse moves). The callback here
/// only buffers the delta and returns immediately.
///
/// A monotonically increasing `generation` token guards the worker lifecycle: a
/// worker only enables the tap and stores its run loop if its captured
/// generation still matches. `stop()` bumps the generation, so a worker that has
/// not yet started running exits without re-enabling an orphaned tap.
final class ScrollEventTap {
    private let engine: SmoothScrollingEngine
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let stateLock = NSLock()
    private var thread: Thread?
    private var activeRunLoop: CFRunLoop?
    private var generation = 0

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

        guard let eventTap, runLoopSource != nil else {
            throw ScrollEventTapError.creationFailed
        }

        let alreadyRunning: Bool = stateLock.withLock {
            if thread != nil {
                return true
            }

            generation += 1
            let gen = generation
            let worker = Thread { [weak self] in
                self?.runTapLoop(generation: gen)
            }
            worker.name = "com.smooth.ScrollEventTap"
            worker.qualityOfService = .userInteractive
            thread = worker
            worker.start()
            return false
        }

        if alreadyRunning {
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    func stop() {
        let runLoop: CFRunLoop? = stateLock.withLock {
            generation += 1
            let active = activeRunLoop
            activeRunLoop = nil
            thread = nil
            return active
        }

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoop {
            CFRunLoopStop(runLoop)
        }
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

    func runTapLoop(generation gen: Int) {
        guard let eventTap, let runLoopSource else {
            return
        }

        let runLoop = CFRunLoopGetCurrent()
        let proceed: Bool = stateLock.withLock {
            guard gen == generation else {
                return false
            }
            activeRunLoop = runLoop
            return true
        }

        guard proceed else {
            return
        }

        CFRunLoopAddSource(runLoop, runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        CFRunLoopRun()
        CFRunLoopRemoveSource(runLoop, runLoopSource, .commonModes)
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
