import SwiftUI
import AppKit
import Combine

@main
struct BattTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var menuBar = MenuBarController()

    var body: some Scene {
        WindowGroup(id: "control") {
            ControlWindowPresenter(app: appViewModel)
                .background(StartupHook(appDelegate: appDelegate, appViewModel: appViewModel, menuBar: menuBar))
        }
        .defaultSize(width: 360, height: 420)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Timer…") {
                    appViewModel.showNewTimerSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandMenu("Timer") {
                Button("Start / Pause") {
                    appViewModel.focusedTimer?.toggleStartPause()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Button("Add +1 Minute") {
                    appViewModel.focusedTimer?.addTime(seconds: 60)
                }
                .keyboardShortcut("=", modifiers: [.command, .shift])

                Divider()

                Button("Show All Windows") {
                    appViewModel.openAllWindows()
                }

                Button("History…") {
                    appViewModel.showHistory = true
                }
            }
        }

        Settings {
            SettingsView(app: appViewModel)
        }
    }
}

/// Gắn AppViewModel vào AppDelegate + khởi tạo menu bar đúng một lần.
private struct StartupHook: View {
    let appDelegate: AppDelegate
    @ObservedObject var appViewModel: AppViewModel
    @ObservedObject var menuBar: MenuBarController

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                appDelegate.bind(appViewModel: appViewModel, menuBar: menuBar)
            }
    }
}

/// AppDelegate — activation policy, notifications, hiện control window.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var appViewModel: AppViewModel?
    private var menuBar: MenuBarController?
    private var didFinishBootstrap = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NotificationService.shared.configure()
    }

    func bind(appViewModel: AppViewModel, menuBar: MenuBarController) {
        self.appViewModel = appViewModel
        self.menuBar = menuBar
        menuBar.setup(app: appViewModel)

        guard !didFinishBootstrap else { return }
        didFinishBootstrap = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self, let app = self.appViewModel else { return }
            if app.timers.isEmpty {
                self.revealControlWindow()
            } else {
                app.openAllWindows()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        revealControlWindow()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotKeyService.shared.stop()
    }

    /// Hiện cửa sổ control đã có; nếu chưa có thì nhờ SwiftUI openWindow qua notification.
    func revealControlWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let existing = NSApp.windows.first(where: {
            $0.identifier?.rawValue == "ControlWindow" || $0.title == "BattTimer"
        }) {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        // Chỉ post khi chưa có cửa sổ — ControlWindowPresenter sẽ openWindow(id:).
        NotificationCenter.default.post(name: .battTimerOpenControl, object: nil)
    }
}
