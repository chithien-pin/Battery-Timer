import Foundation

/// Preset timer có sẵn — Pomodoro, nghỉ, luộc trứng…
struct TimerPreset: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var seconds: TimeInterval
    var theme: TimerTheme
    var soundName: String
    /// SF Symbol name cho menu/UI.
    var symbolName: String

    init(
        id: UUID = UUID(),
        name: String,
        seconds: TimeInterval,
        theme: TimerTheme = .system,
        soundName: String = "Glass",
        symbolName: String = "timer"
    ) {
        self.id = id
        self.name = name
        self.seconds = seconds
        self.theme = theme
        self.soundName = soundName
        self.symbolName = symbolName
    }

    /// Các preset mặc định khi lần đầu mở app.
    static let builtIn: [TimerPreset] = [
        TimerPreset(name: "Pomodoro", seconds: 25 * 60, theme: .ember, soundName: "Glass", symbolName: "flame"),
        TimerPreset(name: "Short Break", seconds: 5 * 60, theme: .ocean, soundName: "Blow", symbolName: "cup.and.saucer"),
        TimerPreset(name: "Long Break", seconds: 15 * 60, theme: .forest, soundName: "Blow", symbolName: "leaf"),
        TimerPreset(name: "Boil Egg", seconds: 7 * 60, theme: .ember, soundName: "Submarine", symbolName: "fork.knife"),
        TimerPreset(name: "Focus Hour", seconds: 60 * 60, theme: .midnight, soundName: "Hero", symbolName: "brain.head.profile"),
        TimerPreset(name: "Quick 1 min", seconds: 60, theme: .mono, soundName: "Ping", symbolName: "bolt"),
    ]
}
