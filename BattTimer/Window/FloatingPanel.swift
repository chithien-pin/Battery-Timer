import AppKit
import SwiftUI

/// NSPanel luôn nổi trên cùng, borderless, có thể kéo và resize.
/// Dùng `.nonactivatingPanel` để không cướp focus khỏi app đang làm việc.
final class FloatingPanel: NSPanel {
    var timerID: UUID
    var onFrameChanged: ((CGRect, String?) -> Void)?
    var onClose: ((UUID) -> Void)?

    private var frameSaveWorkItem: DispatchWorkItem?

    init(
        timerID: UUID,
        contentRect: CGRect,
        useScreenSaverLevel: Bool
    ) {
        self.timerID = timerID
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable, .fullSizeContentView, .nonactivatingPanel, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = useScreenSaverLevel ? .screenSaver : .floating
        // Không kết hợp canJoinAllSpaces với moveToActiveSpace — AppKit sẽ assert.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        // Cho phép cửa sổ nhận key để text field / hotkey local hoạt động khi cần
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
        minSize = NSSize(width: 160, height: 80)
        isReleasedWhenClosed = false
        // Tránh titlebar chrome dù styleMask có closable
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        // Theo dõi di chuyển / resize để lưu frame
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(frameDidChange),
            name: NSWindow.didMoveNotification,
            object: self
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(frameDidChange),
            name: NSWindow.didResizeNotification,
            object: self
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Click-through: chuột xuyên qua khi chỉ xem.
    func setClickThrough(_ enabled: Bool) {
        ignoresMouseEvents = enabled
    }

    func applyDisplayMode(_ mode: DisplayMode) {
        switch mode {
        case .hud:
            hasShadow = false
            backgroundColor = .clear
        case .compact, .normal:
            hasShadow = true
            backgroundColor = .clear
        }
    }

    func centerOnActiveScreen(enlarge: Bool) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        var size = frame.size
        if enlarge {
            size.width = max(size.width, 420)
            size.height = max(size.height, 220)
        }
        let origin = CGPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2
        )
        setFrame(CGRect(origin: origin, size: size), display: true, animate: true)
    }

    @objc private func frameDidChange() {
        // Debounce lưu frame để tránh ghi UserDefaults quá dày
        frameSaveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let screenID = Self.screenIdentifier(self.screen)
            self.onFrameChanged?(self.frame, screenID)
        }
        frameSaveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    override func close() {
        onClose?(timerID)
        super.close()
    }

    /// ID ổn định cho multi-display (NSScreenNumber trong deviceDescription).
    static func screenIdentifier(_ screen: NSScreen?) -> String? {
        guard let num = screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return num.stringValue
    }
}

/// Host SwiftUI view bên trong FloatingPanel.
final class PanelHostingController<Content: View>: NSHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
    }
}
