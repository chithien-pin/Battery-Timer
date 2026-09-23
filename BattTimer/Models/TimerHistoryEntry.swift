import Foundation

/// Một bản ghi lịch sử timer đã chạy xong (hoặc bị huỷ).
struct TimerHistoryEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var plannedSeconds: TimeInterval
    var actualSeconds: TimeInterval
    var completed: Bool
    var finishedAt: Date
    var theme: TimerTheme

    init(
        id: UUID = UUID(),
        title: String,
        plannedSeconds: TimeInterval,
        actualSeconds: TimeInterval,
        completed: Bool,
        finishedAt: Date = Date(),
        theme: TimerTheme = .system
    ) {
        self.id = id
        self.title = title
        self.plannedSeconds = plannedSeconds
        self.actualSeconds = actualSeconds
        self.completed = completed
        self.finishedAt = finishedAt
        self.theme = theme
    }
}
