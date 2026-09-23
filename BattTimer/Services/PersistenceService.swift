import Foundation

/// Persist timers, history, presets, preferences qua UserDefaults.
final class PersistenceService {
    static let shared = PersistenceService()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let timers = "battTimer.timers"
        static let history = "battTimer.history"
        static let presets = "battTimer.presets"
        static let preferences = "battTimer.preferences"
    }

    private init() {}

    // MARK: - Timers

    func saveTimers(_ timers: [TimerModel]) {
        save(timers, key: Key.timers)
    }

    func loadTimers() -> [TimerModel] {
        load(key: Key.timers) ?? []
    }

    // MARK: - History

    func saveHistory(_ entries: [TimerHistoryEntry]) {
        // Giữ tối đa 100 bản ghi gần nhất
        let trimmed = Array(entries.prefix(100))
        save(trimmed, key: Key.history)
    }

    func loadHistory() -> [TimerHistoryEntry] {
        load(key: Key.history) ?? []
    }

    // MARK: - Presets

    func savePresets(_ presets: [TimerPreset]) {
        save(presets, key: Key.presets)
    }

    func loadPresets() -> [TimerPreset] {
        if let stored: [TimerPreset] = load(key: Key.presets), !stored.isEmpty {
            return stored
        }
        return TimerPreset.builtIn
    }

    // MARK: - Preferences

    func savePreferences(_ prefs: AppPreferences) {
        save(prefs, key: Key.preferences)
    }

    func loadPreferences() -> AppPreferences {
        load(key: Key.preferences) ?? .defaults
    }

    // MARK: - Helpers

    private func save<T: Encodable>(_ value: T, key: String) {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        } catch {
            print("[Persistence] Encode failed for \(key): \(error)")
        }
    }

    private func load<T: Decodable>(key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[Persistence] Decode failed for \(key): \(error)")
            return nil
        }
    }
}

/// Tuỳ chọn toàn cục của app.
struct AppPreferences: Codable, Equatable {
    var bypassFocusMode: Bool
    var autoCenterOnFinish: Bool
    var enlargeOnFinish: Bool
    var defaultSound: String
    var defaultTheme: TimerTheme
    var defaultDisplayMode: DisplayMode
    /// Window level: floating vs screenSaver (nổi trên fullscreen).
    var useScreenSaverLevel: Bool
    /// Thời lượng mặc định khi tạo timer mới (giây).
    var defaultDurationSeconds: TimeInterval

    static let defaults = AppPreferences(
        bypassFocusMode: true,
        autoCenterOnFinish: true,
        enlargeOnFinish: false,
        defaultSound: "Glass",
        defaultTheme: .system,
        defaultDisplayMode: .normal,
        useScreenSaverLevel: false,
        defaultDurationSeconds: 25 * 60
    )

    enum CodingKeys: String, CodingKey {
        case bypassFocusMode, autoCenterOnFinish, enlargeOnFinish
        case defaultSound, defaultTheme, defaultDisplayMode
        case useScreenSaverLevel, defaultDurationSeconds
    }

    init(
        bypassFocusMode: Bool,
        autoCenterOnFinish: Bool,
        enlargeOnFinish: Bool,
        defaultSound: String,
        defaultTheme: TimerTheme,
        defaultDisplayMode: DisplayMode,
        useScreenSaverLevel: Bool,
        defaultDurationSeconds: TimeInterval
    ) {
        self.bypassFocusMode = bypassFocusMode
        self.autoCenterOnFinish = autoCenterOnFinish
        self.enlargeOnFinish = enlargeOnFinish
        self.defaultSound = defaultSound
        self.defaultTheme = defaultTheme
        self.defaultDisplayMode = defaultDisplayMode
        self.useScreenSaverLevel = useScreenSaverLevel
        self.defaultDurationSeconds = defaultDurationSeconds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bypassFocusMode = try c.decodeIfPresent(Bool.self, forKey: .bypassFocusMode) ?? true
        autoCenterOnFinish = try c.decodeIfPresent(Bool.self, forKey: .autoCenterOnFinish) ?? true
        enlargeOnFinish = try c.decodeIfPresent(Bool.self, forKey: .enlargeOnFinish) ?? false
        defaultSound = try c.decodeIfPresent(String.self, forKey: .defaultSound) ?? "Glass"
        defaultTheme = try c.decodeIfPresent(TimerTheme.self, forKey: .defaultTheme) ?? .system
        defaultDisplayMode = try c.decodeIfPresent(DisplayMode.self, forKey: .defaultDisplayMode) ?? .normal
        useScreenSaverLevel = try c.decodeIfPresent(Bool.self, forKey: .useScreenSaverLevel) ?? false
        defaultDurationSeconds = try c.decodeIfPresent(TimeInterval.self, forKey: .defaultDurationSeconds) ?? 25 * 60
    }
}
