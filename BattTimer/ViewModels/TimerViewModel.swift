import Foundation
import Combine

/// ViewModel cho một timer riêng lẻ — tick mỗi giây dựa trên wall-clock (`endDate`)
/// để không bị lệch khi app sleep / throttle.
@MainActor
final class TimerViewModel: ObservableObject, Identifiable {
    let id: UUID

    @Published private(set) var model: TimerModel
    @Published private(set) var displaySeconds: TimeInterval
    @Published var shakeTrigger: Int = 0
    @Published var isAlerting: Bool = false

    /// Gọi khi timer chuyển sang finished.
    var onFinished: ((TimerModel) -> Void)?
    /// Gọi mỗi khi model thay đổi (để AppViewModel persist).
    var onChanged: ((TimerModel) -> Void)?

    private var tickTimer: AnyCancellable?
    private let tickInterval: TimeInterval = 0.25

    init(model: TimerModel) {
        self.id = model.id
        self.model = model
        self.displaySeconds = model.remainingSeconds

        // Khôi phục timer đang chạy sau khi reopen app
        if model.status == .running, let end = model.endDate {
            let remaining = end.timeIntervalSinceNow
            if remaining <= 0 {
                finish()
            } else {
                self.model.remainingSeconds = remaining
                self.displaySeconds = remaining
                startTicking()
            }
        }
    }

    // MARK: - Controls

    func start() {
        guard model.status != .running else { return }
        guard model.remainingSeconds > 0 else {
            finish()
            return
        }
        model.status = .running
        model.endDate = Date().addingTimeInterval(model.remainingSeconds)
        isAlerting = false
        publish()
        startTicking()
    }

    func pause() {
        guard model.status == .running else { return }
        syncRemainingFromEndDate()
        model.status = .paused
        model.endDate = nil
        stopTicking()
        publish()
    }

    func toggleStartPause() {
        switch model.status {
        case .running:
            pause()
        case .idle, .paused, .finished:
            if model.status == .finished {
                reset()
            }
            start()
        }
    }

    func reset() {
        stopTicking()
        SoundService.shared.stop()
        model.remainingSeconds = model.totalSeconds
        model.status = .idle
        model.endDate = nil
        displaySeconds = model.totalSeconds
        isAlerting = false
        publish()
    }

    func addTime(seconds: TimeInterval) {
        model.remainingSeconds += seconds
        model.totalSeconds = max(model.totalSeconds, model.remainingSeconds)
        if model.status == .finished {
            model.status = .paused
            isAlerting = false
            SoundService.shared.stop()
        }
        if model.status == .running {
            model.endDate = Date().addingTimeInterval(model.remainingSeconds)
        }
        displaySeconds = model.remainingSeconds
        publish()
    }

    func setDuration(seconds: TimeInterval) {
        guard model.status == .idle || model.status == .paused || model.status == .finished else { return }
        model.totalSeconds = max(1, seconds)
        model.remainingSeconds = model.totalSeconds
        model.status = .idle
        model.endDate = nil
        displaySeconds = model.totalSeconds
        isAlerting = false
        publish()
    }

    func updateTitle(_ title: String) {
        model.title = title
        publish()
    }

    func updateTheme(_ theme: TimerTheme) {
        model.theme = theme
        publish()
    }

    func updateSound(_ name: String) {
        model.soundName = name
        publish()
    }

    func updateDisplayMode(_ mode: DisplayMode) {
        model.displayMode = mode
        publish()
    }

    func updateClickThrough(_ enabled: Bool) {
        model.clickThrough = enabled
        publish()
    }

    func updateFrame(_ frame: SavedWindowFrame, screenID: String?) {
        model.savedFrame = frame
        model.screenID = screenID
        // Không gọi onChanged liên tục qua publish đầy đủ — AppViewModel handle riêng
        onChanged?(model)
    }

    func acknowledgeAlert() {
        isAlerting = false
        SoundService.shared.stop()
    }

    // MARK: - Ticking

    private func startTicking() {
        stopTicking()
        tickTimer = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTicking() {
        tickTimer?.cancel()
        tickTimer = nil
    }

    private func tick() {
        guard model.status == .running else { return }
        syncRemainingFromEndDate()
        displaySeconds = max(0, model.remainingSeconds)
        if model.remainingSeconds <= 0 {
            finish()
        }
    }

    private func syncRemainingFromEndDate() {
        if let end = model.endDate {
            model.remainingSeconds = max(0, end.timeIntervalSinceNow)
        }
    }

    private func finish() {
        stopTicking()
        model.remainingSeconds = 0
        displaySeconds = 0
        model.status = .finished
        model.endDate = nil
        isAlerting = true
        shakeTrigger += 1
        publish()
        onFinished?(model)
    }

    private func publish() {
        objectWillChange.send()
        onChanged?(model)
    }

    func teardown() {
        stopTicking()
        SoundService.shared.stop()
    }
}
