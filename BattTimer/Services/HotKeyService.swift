import AppKit
import Carbon.HIToolbox

/// Global / local keyboard shortcut để Start/Pause timer đang focus.
/// Dùng NSEvent monitors — yêu cầu Accessibility permission cho global monitor.
final class HotKeyService {
    static let shared = HotKeyService()

    /// Callback khi hotkey được kích hoạt.
    var onTogglePause: (() -> Void)?
    var onAddOneMinute: (() -> Void)?
    var onNewTimer: (() -> Void)?

    private var localMonitor: Any?
    private var globalMonitor: Any?

    /// ⌘⇧T = toggle pause, ⌘⇧= = +1 phút, ⌘⇧N = timer mới
    private let toggleKey: UInt16 = 17      // T
    private let addMinuteKey: UInt16 = 24   // =
    private let newTimerKey: UInt16 = 45    // N

    private init() {}

    func start() {
        stop()

        let handler: (NSEvent) -> NSEvent? = { [weak self] event in
            guard let self, event.modifierFlags.contains([.command, .shift]) else {
                return event
            }
            switch event.keyCode {
            case self.toggleKey:
                self.onTogglePause?()
                return nil
            case self.addMinuteKey:
                self.onAddOneMinute?()
                return nil
            case self.newTimerKey:
                self.onNewTimer?()
                return nil
            default:
                return event
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: handler)

        // Global monitor chỉ nhận event, không thể nuốt — và cần Accessibility.
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.modifierFlags.contains([.command, .shift]) else { return }
            switch event.keyCode {
            case self.toggleKey:
                DispatchQueue.main.async { self.onTogglePause?() }
            case self.addMinuteKey:
                DispatchQueue.main.async { self.onAddOneMinute?() }
            case self.newTimerKey:
                DispatchQueue.main.async { self.onNewTimer?() }
            default:
                break
            }
        }
    }

    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }
}
