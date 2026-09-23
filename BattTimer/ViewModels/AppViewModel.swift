import Foundation
import Combine
import AppKit
import SwiftUI

/// ViewModel gốc — sở hữu danh sách timer, history, presets, preferences,
/// kết nối WindowManager / MenuBar / HotKey / Notification.
@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var timers: [TimerViewModel] = []
    @Published var history: [TimerHistoryEntry] = []
    @Published var presets: [TimerPreset] = []
    @Published var preferences: AppPreferences
    @Published var showNewTimerSheet = false
    @Published var showSettings = false
    @Published var showHistory = false
    @Published var focusedTimerID: UUID?

    private let persistence = PersistenceService.shared
    private let windows = WindowManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        preferences = persistence.loadPreferences()
        presets = persistence.loadPresets()
        history = persistence.loadHistory()

        NotificationService.shared.bypassFocusMode = preferences.bypassFocusMode
        windows.configure(useScreenSaverLevel: preferences.useScreenSaverLevel)

        // Khôi phục timers đã lưu
        let saved = persistence.loadTimers()
        for model in saved {
            attach(makeViewModel(from: model))
        }

        windows.onFrameChanged = { [weak self] id, frame, screenID in
            self?.timers.first(where: { $0.id == id })?.updateFrame(frame, screenID: screenID)
            self?.persistTimers()
        }
        windows.onPanelClosed = { [weak self] id in
            // Đóng cửa sổ ≠ xoá timer — giữ trong list để mở lại từ menu bar
            self?.focusedTimerID = self?.timers.first?.id
        }

        setupHotKeys()
    }

    // MARK: - Timer CRUD

    @discardableResult
    func createTimer(
        title: String = "Timer",
        seconds: TimeInterval,
        theme: TimerTheme? = nil,
        sound: String? = nil,
        displayMode: DisplayMode? = nil,
        autoStart: Bool = false
    ) -> TimerViewModel {
        var model = TimerModel(
            title: title,
            totalSeconds: seconds,
            theme: theme ?? preferences.defaultTheme,
            soundName: sound ?? preferences.defaultSound,
            displayMode: displayMode ?? preferences.defaultDisplayMode
        )
        // Cascade frame mặc định sẽ do WindowManager xử lý
        let vm = makeViewModel(from: model)
        attach(vm)
        openWindow(for: vm)
        if autoStart { vm.start() }
        persistTimers()
        return vm
    }

    func createFromPreset(_ preset: TimerPreset, autoStart: Bool = true) {
        createTimer(
            title: preset.name,
            seconds: preset.seconds,
            theme: preset.theme,
            sound: preset.soundName,
            autoStart: autoStart
        )
    }

    func removeTimer(id: UUID) {
        if let vm = timers.first(where: { $0.id == id }) {
            // Ghi history nếu đang chạy / pause
            if vm.model.status == .running || vm.model.status == .paused {
                appendHistory(from: vm.model, completed: false)
            }
            vm.teardown()
        }
        windows.close(id: id)
        timers.removeAll { $0.id == id }
        if focusedTimerID == id {
            focusedTimerID = timers.first?.id
        }
        persistTimers()
    }

    func openWindow(for vm: TimerViewModel) {
        focusedTimerID = vm.id
        windows.showTimerWindow(for: vm.model) {
            TimerWindowView(viewModel: vm, app: self)
        }
        windows.applyDisplayMode(vm.model.displayMode, for: vm.id)
        windows.setClickThrough(vm.model.clickThrough, for: vm.id)
    }

    func openAllWindows() {
        for vm in timers {
            openWindow(for: vm)
        }
    }

    func focusTimer(id: UUID) {
        focusedTimerID = id
        if windows.isOpen(id) {
            windows.focus(id: id)
        } else if let vm = timers.first(where: { $0.id == id }) {
            openWindow(for: vm)
        }
    }

    var focusedTimer: TimerViewModel? {
        if let id = focusedTimerID {
            return timers.first { $0.id == id }
        }
        return timers.first
    }

    // MARK: - Preferences

    func updatePreferences(_ prefs: AppPreferences) {
        preferences = prefs
        persistence.savePreferences(prefs)
        NotificationService.shared.bypassFocusMode = prefs.bypassFocusMode
        windows.configure(useScreenSaverLevel: prefs.useScreenSaverLevel)
    }

    func savePresets() {
        persistence.savePresets(presets)
    }

    func clearHistory() {
        history = []
        persistence.saveHistory(history)
    }

    // MARK: - Private

    private func makeViewModel(from model: TimerModel) -> TimerViewModel {
        let vm = TimerViewModel(model: model)
        vm.onChanged = { [weak self] updated in
            self?.handleModelChange(updated)
        }
        vm.onFinished = { [weak self] finished in
            self?.handleFinished(finished)
        }
        return vm
    }

    private func attach(_ vm: TimerViewModel) {
        timers.append(vm)
        if focusedTimerID == nil {
            focusedTimerID = vm.id
        }
    }

    private func handleModelChange(_ model: TimerModel) {
        // Đồng bộ click-through / display mode với cửa sổ
        windows.setClickThrough(model.clickThrough, for: model.id)
        windows.applyDisplayMode(model.displayMode, for: model.id)
        persistTimers()
    }

    private func handleFinished(_ model: TimerModel) {
        SoundService.shared.playAlert(model.soundName, times: 3)
        NotificationService.shared.sendTimerFinished(title: model.title, timerID: model.id)
        windows.bringToFrontOnFinish(
            id: model.id,
            center: preferences.autoCenterOnFinish,
            enlarge: preferences.enlargeOnFinish
        )
        appendHistory(from: model, completed: true)
        persistTimers()
    }

    private func appendHistory(from model: TimerModel, completed: Bool) {
        let entry = TimerHistoryEntry(
            title: model.title,
            plannedSeconds: model.totalSeconds,
            actualSeconds: model.totalSeconds - model.remainingSeconds,
            completed: completed,
            theme: model.theme
        )
        history.insert(entry, at: 0)
        persistence.saveHistory(history)
    }

    private func persistTimers() {
        let models = timers.map(\.model)
        persistence.saveTimers(models)
    }

    private func setupHotKeys() {
        let hotkeys = HotKeyService.shared
        hotkeys.onTogglePause = { [weak self] in
            self?.focusedTimer?.toggleStartPause()
        }
        hotkeys.onAddOneMinute = { [weak self] in
            self?.focusedTimer?.addTime(seconds: 60)
        }
        hotkeys.onNewTimer = { [weak self] in
            self?.showNewTimerSheet = true
        }
        hotkeys.start()
    }
}
