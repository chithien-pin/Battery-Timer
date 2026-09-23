import Combine
import AppKit
import SwiftUI

/// Status bar item — quick access tạo / điều khiển timer mà không cần cửa sổ chính.
@MainActor
final class MenuBarController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private weak var app: AppViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var didSetup = false

    func setup(app: AppViewModel) {
        guard !didSetup else { return }
        didSetup = true
        self.app = app

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "BattTimer")
            button.image?.isTemplate = true
        }
        statusItem = item
        rebuildMenu()

        app.$timers
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateButtonTitle()
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        // Tick menu bar title ~1s khi có timer chạy
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateButtonTitle()
            }
            .store(in: &cancellables)
    }

    private func updateButtonTitle() {
        guard let button = statusItem?.button else { return }
        if let running = app?.timers.first(where: { $0.model.status == .running }) {
            button.title = " " + TimeFormatter.countdown(running.displaySeconds)
        } else {
            button.title = ""
        }
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let newItem = menu.addItem(withTitle: "New Timer…", action: #selector(newTimer), keyEquivalent: "n")
        newItem.target = self
        menu.addItem(NSMenuItem.separator())

        let presetsMenu = NSMenu()
        for preset in app?.presets ?? TimerPreset.builtIn {
            let item = NSMenuItem(
                title: "\(preset.name) (\(TimeFormatter.compact(preset.seconds)))",
                action: #selector(startPreset(_:)),
                keyEquivalent: ""
            )
            item.representedObject = preset.id.uuidString
            item.target = self
            presetsMenu.addItem(item)
        }
        let presetsRoot = NSMenuItem(title: "Presets", action: nil, keyEquivalent: "")
        presetsRoot.submenu = presetsMenu
        menu.addItem(presetsRoot)
        menu.addItem(NSMenuItem.separator())

        if let timers = app?.timers, !timers.isEmpty {
            for vm in timers {
                let title = "\(vm.model.title) — \(TimeFormatter.countdown(vm.displaySeconds))"
                let item = NSMenuItem(title: title, action: #selector(focusTimer(_:)), keyEquivalent: "")
                item.representedObject = vm.id.uuidString
                item.target = self
                menu.addItem(item)
            }
            menu.addItem(NSMenuItem.separator())

            if app?.focusedTimer != nil {
                let toggle = menu.addItem(withTitle: "Start / Pause", action: #selector(toggleFocused), keyEquivalent: "")
                toggle.target = self
                let add1 = menu.addItem(withTitle: "Add +1 min", action: #selector(addOneMin), keyEquivalent: "")
                add1.target = self
                let add5 = menu.addItem(withTitle: "Add +5 min", action: #selector(addFiveMin), keyEquivalent: "")
                add5.target = self
                let add30 = menu.addItem(withTitle: "Add +30 min", action: #selector(addThirtyMin), keyEquivalent: "")
                add30.target = self
                let reset = menu.addItem(withTitle: "Reset", action: #selector(resetFocused), keyEquivalent: "")
                reset.target = self
                menu.addItem(NSMenuItem.separator())
            }
        }

        menu.addItem(withTitle: "Show All Windows", action: #selector(showAll), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Open Control Panel", action: #selector(openControl), keyEquivalent: "").target = self
        menu.addItem(withTitle: "History…", action: #selector(showHistory), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",").target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit BattTimer", action: #selector(quit), keyEquivalent: "q").target = self

        statusItem?.menu = menu
    }

    @objc private func newTimer() {
        app?.showNewTimerSheet = true
        openControl()
    }

    @objc private func startPreset(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let id = UUID(uuidString: raw),
              let preset = app?.presets.first(where: { $0.id == id }) else { return }
        app?.createFromPreset(preset, autoStart: true)
    }

    @objc private func focusTimer(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let id = UUID(uuidString: raw) else { return }
        app?.focusTimer(id: id)
    }

    @objc private func toggleFocused() { app?.focusedTimer?.toggleStartPause() }
    @objc private func addOneMin() { app?.focusedTimer?.addTime(seconds: 60) }
    @objc private func addFiveMin() { app?.focusedTimer?.addTime(seconds: 5 * 60) }
    @objc private func addThirtyMin() { app?.focusedTimer?.addTime(seconds: 30 * 60) }
    @objc private func resetFocused() { app?.focusedTimer?.reset() }
    @objc private func showAll() { app?.openAllWindows() }

    @objc private func openControl() {
        NotificationCenter.default.post(name: .battTimerOpenControl, object: nil)
    }

    @objc private func showHistory() {
        app?.showHistory = true
        openControl()
    }

    @objc private func showSettings() {
        app?.showSettings = true
        openControl()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension Notification.Name {
    static let battTimerOpenControl = Notification.Name("battTimer.openControl")
}
