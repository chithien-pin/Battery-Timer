import Foundation

enum TimeFormatter {
    /// Định dạng HH:MM:SS hoặc MM:SS tuỳ theo độ dài.
    static func countdown(_ totalSeconds: TimeInterval) -> String {
        let clamped = max(0, Int(totalSeconds.rounded(.down)))
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let seconds = clamped % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Định dạng ngắn cho menu bar / history (vd: "25m", "1h 30m").
    static func compact(_ totalSeconds: TimeInterval) -> String {
        let clamped = max(0, Int(totalSeconds.rounded(.down)))
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let seconds = clamped % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 && seconds > 0 && minutes < 5 {
            return "\(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m"
        }
        return "\(seconds)s"
    }

    /// Parse chuỗi "25" hoặc "1:30" hoặc "1:30:00" thành giây.
    static func parseDuration(_ text: String) -> TimeInterval? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(separator: ":").map(String.init)
        switch parts.count {
        case 1:
            // Chỉ phút, hoặc số giây nếu có hậu tố s
            if let value = Double(parts[0]) {
                return value * 60
            }
        case 2:
            guard let m = Int(parts[0]), let s = Int(parts[1]),
                  m >= 0, s >= 0, s < 60 else { return nil }
            return TimeInterval(m * 60 + s)
        case 3:
            guard let h = Int(parts[0]), let m = Int(parts[1]), let s = Int(parts[2]),
                  h >= 0, m >= 0, m < 60, s >= 0, s < 60 else { return nil }
            return TimeInterval(h * 3600 + m * 60 + s)
        default:
            return nil
        }
        return nil
    }

    /// Tính số giây từ "bây giờ" đến một thời điểm trong ngày (giờ:phút).
    /// Nếu đã qua, tính tới cùng giờ ngày mai.
    static func secondsUntil(hour: Int, minute: Int, from date: Date = Date()) -> TimeInterval {
        var calendar = Calendar.current
        calendar.timeZone = .current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard var target = calendar.date(from: components) else { return 0 }
        if target <= date {
            target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
        }
        return target.timeIntervalSince(date)
    }
}
