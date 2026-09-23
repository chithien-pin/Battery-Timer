import AppKit
import SwiftUI

/// Quản lý vòng đời các cửa sổ timer floating.
/// Mỗi timer = một FloatingPanel riêng — dễ kéo ra nhiều màn hình.
@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()

    @Published private(set) var openTimerIDs: [UUID] = []

    private var panels: [UUID: FloatingPanel] = [:]
    private var hostingControllers: [UUID: NSViewController] = [:]

    /// Callback khi frame thay đổi — AppViewModel sẽ persist.
    var onFrameChanged: ((UUID, SavedWindowFrame, String?) -> Void)?
    /// Callback khi user đóng cửa sổ.
    var onPanelClosed: ((UUID) -> Void)?

    private var useScreenSaverLevel = false

    private init() {}

    func configure(useScreenSaverLevel: Bool) {
        self.useScreenSaverLevel = useScreenSaverLevel
        for panel in panels.values {
            panel.level = useScreenSaverLevel ? .screenSaver : .floating
        }
    }

    /// Mở (hoặc hiện lại) cửa sổ cho một timer.
    func showTimerWindow<Content: View>(
        for model: TimerModel,
        @ViewBuilder content: () -> Content
    ) {
        if let existing = panels[model.id] {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let defaultSize = CGSize(width: 320, height: 180)
        var rect = CGRect(origin: .zero, size: defaultSize)

        if let saved = model.savedFrame?.cgRect, saved.width > 50, saved.height > 50 {
            rect = saved
            // Nếu screenID còn tồn tại, giữ nguyên; nếu không, clamp vào màn chính.
            if let screenID = model.screenID,
               let screen = NSScreen.screens.first(where: {
                   FloatingPanel.screenIdentifier($0) == screenID
               }) {
                rect = clamp(rect, to: screen.visibleFrame)
            } else if let screen = NSScreen.main {
                rect = clamp(rect, to: screen.visibleFrame)
            }
        } else {
            // Cascade các cửa sổ mới để không đè lên nhau
            let offset = CGFloat(panels.count) * 28
            if let screen = NSScreen.main {
                let mid = CGPoint(x: screen.visibleFrame.midX, y: screen.visibleFrame.midY)
                rect.origin = CGPoint(
                    x: mid.x - defaultSize.width / 2 + offset,
                    y: mid.y - defaultSize.height / 2 - offset
                )
            }
        }

        let panel = FloatingPanel(
            timerID: model.id,
            contentRect: rect,
            useScreenSaverLevel: useScreenSaverLevel
        )

        let host = PanelHostingController(rootView: content())
        host.view.frame = panel.contentView?.bounds ?? rect
        host.view.autoresizingMask = [.width, .height]
        panel.contentView = host.view

        panel.onFrameChanged = { [weak self] frame, screenID in
            self?.onFrameChanged?(model.id, SavedWindowFrame(frame), screenID)
        }
        panel.onClose = { [weak self] id in
            self?.removePanel(id: id)
            self?.onPanelClosed?(id)
        }

        panel.applyDisplayMode(model.displayMode)
        panel.setClickThrough(model.clickThrough)

        panels[model.id] = panel
        hostingControllers[model.id] = host
        if !openTimerIDs.contains(model.id) {
            openTimerIDs.append(model.id)
        }

        panel.makeKeyAndOrderFront(nil)
    }

    /// Cập nhật SwiftUI content khi model đổi (theme, mode…).
    func updateContent<Content: View>(for id: UUID, @ViewBuilder content: () -> Content) {
        guard let panel = panels[id] else { return }
        let host = PanelHostingController(rootView: content())
        host.view.frame = panel.contentView?.bounds ?? .zero
        host.view.autoresizingMask = [.width, .height]
        panel.contentView = host.view
        hostingControllers[id] = host
    }

    func setClickThrough(_ enabled: Bool, for id: UUID) {
        panels[id]?.setClickThrough(enabled)
    }

    func applyDisplayMode(_ mode: DisplayMode, for id: UUID) {
        panels[id]?.applyDisplayMode(mode)
    }

    func focus(id: UUID) {
        panels[id]?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func bringToFrontOnFinish(id: UUID, center: Bool, enlarge: Bool) {
        guard let panel = panels[id] else { return }
        panel.level = useScreenSaverLevel ? .screenSaver : .floating
        if center || enlarge {
            panel.centerOnActiveScreen(enlarge: enlarge)
        }
        panel.setClickThrough(false) // đảm bảo tương tác được khi hết giờ
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close(id: UUID) {
        panels[id]?.close()
    }

    func closeAll() {
        for id in Array(panels.keys) {
            panels[id]?.close()
        }
    }

    func isOpen(_ id: UUID) -> Bool {
        panels[id] != nil
    }

    private func removePanel(id: UUID) {
        panels.removeValue(forKey: id)
        hostingControllers.removeValue(forKey: id)
        openTimerIDs.removeAll { $0 == id }
    }

    private func clamp(_ rect: CGRect, to visible: CGRect) -> CGRect {
        var r = rect
        if r.width > visible.width { r.size.width = visible.width * 0.8 }
        if r.height > visible.height { r.size.height = visible.height * 0.8 }
        if r.minX < visible.minX { r.origin.x = visible.minX + 20 }
        if r.minY < visible.minY { r.origin.y = visible.minY + 20 }
        if r.maxX > visible.maxX { r.origin.x = visible.maxX - r.width - 20 }
        if r.maxY > visible.maxY { r.origin.y = visible.maxY - r.height - 20 }
        return r
    }
}
