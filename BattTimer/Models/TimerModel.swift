import Foundation
import CoreGraphics

/// Trạng thái vòng đời của một countdown timer.
enum TimerStatus: String, Codable, Equatable {
    case idle
    case running
    case paused
    case finished
}

/// Chế độ hiển thị cửa sổ timer.
enum DisplayMode: String, Codable, CaseIterable, Identifiable {
    case normal      // Đầy đủ controls
    case compact     // Chỉ số + controls nhỏ
    case hud         // Chỉ số, nền trong suốt, không viền

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal:  return "Normal"
        case .compact: return "Compact"
        case .hud:     return "HUD"
        }
    }
}

/// Model dữ liệu thuần (Codable) cho một timer — dễ persist & đồng bộ.
struct TimerModel: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    /// Tổng thời lượng ban đầu (giây).
    var totalSeconds: TimeInterval
    /// Thời gian còn lại (giây).
    var remainingSeconds: TimeInterval
    var status: TimerStatus
    /// Thời điểm tường (wall-clock) khi timer sẽ kết thúc nếu đang chạy.
    var endDate: Date?
    var theme: TimerTheme
    var soundName: String
    var displayMode: DisplayMode
    /// Cho phép chuột xuyên qua cửa sổ (chỉ xem).
    var clickThrough: Bool
    /// Frame cửa sổ đã lưu (origin + size) theo màn hình.
    var savedFrame: SavedWindowFrame?
    /// Screen ID nơi cửa sổ nằm lần trước (multi-display).
    var screenID: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String = "Timer",
        totalSeconds: TimeInterval = 25 * 60,
        remainingSeconds: TimeInterval? = nil,
        status: TimerStatus = .idle,
        endDate: Date? = nil,
        theme: TimerTheme = .system,
        soundName: String = "Glass",
        displayMode: DisplayMode = .normal,
        clickThrough: Bool = false,
        savedFrame: SavedWindowFrame? = nil,
        screenID: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.totalSeconds = totalSeconds
        self.remainingSeconds = remainingSeconds ?? totalSeconds
        self.status = status
        self.endDate = endDate
        self.theme = theme
        self.soundName = soundName
        self.displayMode = displayMode
        self.clickThrough = clickThrough
        self.savedFrame = savedFrame
        self.screenID = screenID
        self.createdAt = createdAt
    }

    /// Tiến độ 0...1 (1 = đầy đủ thời gian còn lại).
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return max(0, min(1, remainingSeconds / totalSeconds))
    }

    var isFinished: Bool { status == .finished || remainingSeconds <= 0 }
}

/// Frame cửa sổ đã lưu — tách CGRect để Codable sạch.
struct SavedWindowFrame: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(_ rect: CGRect) {
        x = rect.origin.x
        y = rect.origin.y
        width = rect.size.width
        height = rect.size.height
    }

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}
