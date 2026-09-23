import AppKit
import AudioToolbox

/// Phát âm thanh cảnh báo khi hết giờ — dùng system sounds macOS.
final class SoundService {
    static let shared = SoundService()

    /// Tên system sound có sẵn (trong /System/Library/Sounds).
    static let availableSounds: [String] = [
        "Glass", "Blow", "Bottle", "Frog", "Funk",
        "Hero", "Morse", "Ping", "Pop", "Purr",
        "Sosumi", "Submarine", "Tink"
    ]

    private var repeatTimer: Timer?
    private var playCount = 0

    private init() {}

    /// Phát một lần.
    func play(_ name: String) {
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        if let sound = NSSound(contentsOf: url, byReference: true) {
            sound.play()
        } else {
            // Fallback: beep hệ thống
            NSSound.beep()
        }
    }

    /// Phát lặp vài lần để không bỏ lỡ.
    func playAlert(_ name: String, times: Int = 3, interval: TimeInterval = 1.2) {
        stop()
        playCount = 0
        play(name)
        playCount = 1

        guard times > 1 else { return }
        repeatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            self.play(name)
            self.playCount += 1
            if self.playCount >= times {
                timer.invalidate()
                self.repeatTimer = nil
            }
        }
    }

    func stop() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        playCount = 0
    }
}
