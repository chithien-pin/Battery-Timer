import SwiftUI
import AppKit

/// Wrapper lắng nghe notification để mở WindowGroup từ MenuBar / reopen.
struct ControlWindowPresenter: View {
    @ObservedObject var app: AppViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ControlWindowView(app: app)
            .background(WindowIdentitySetter())
            .onReceive(NotificationCenter.default.publisher(for: .battTimerOpenControl)) { _ in
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "control")
                NSApp.activate(ignoringOtherApps: true)

                // Focus cửa sổ control nếu đã tồn tại (tránh phụ thuộc openWindow tạo mới).
                DispatchQueue.main.async {
                    if let existing = NSApp.windows.first(where: {
                        $0.identifier?.rawValue == "ControlWindow" || $0.title == "BattTimer"
                    }) {
                        existing.makeKeyAndOrderFront(nil)
                    }
                }
            }
    }
}

/// Gắn identifier cho NSWindow để tìm lại sau này.
private struct WindowIdentitySetter: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            apply(to: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        apply(to: nsView.window)
    }

    private func apply(to window: NSWindow?) {
        window?.identifier = NSUserInterfaceItemIdentifier("ControlWindow")
        window?.title = "BattTimer"
    }
}
