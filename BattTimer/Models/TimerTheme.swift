import SwiftUI

/// Theme màu cho cửa sổ timer — hỗ trợ theo hệ thống hoặc custom.
enum TimerTheme: String, Codable, CaseIterable, Identifiable {
    case system
    case ocean
    case ember
    case forest
    case midnight
    case mono

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:   return "System"
        case .ocean:    return "Ocean"
        case .ember:    return "Ember"
        case .forest:   return "Forest"
        case .midnight: return "Midnight"
        case .mono:     return "Mono"
        }
    }

    /// Màu chữ số đếm ngược.
    var digitColor: Color {
        switch self {
        case .system:   return Color.primary
        case .ocean:    return Color(red: 0.35, green: 0.78, blue: 0.95)
        case .ember:    return Color(red: 1.00, green: 0.55, blue: 0.25)
        case .forest:   return Color(red: 0.40, green: 0.85, blue: 0.55)
        case .midnight: return Color(red: 0.70, green: 0.75, blue: 1.00)
        case .mono:     return Color.white
        }
    }

    /// Màu nền cửa sổ (opacity thấp cho HUD).
    var backgroundColor: Color {
        switch self {
        case .system:   return Color(nsColor: .windowBackgroundColor)
        case .ocean:    return Color(red: 0.06, green: 0.12, blue: 0.20)
        case .ember:    return Color(red: 0.18, green: 0.08, blue: 0.05)
        case .forest:   return Color(red: 0.06, green: 0.14, blue: 0.08)
        case .midnight: return Color(red: 0.08, green: 0.08, blue: 0.16)
        case .mono:     return Color.black
        }
    }

    /// Màu khi hết giờ (cảnh báo).
    var alertColor: Color {
        switch self {
        case .system:   return Color.red
        case .ocean:    return Color(red: 1.0, green: 0.4, blue: 0.5)
        case .ember:    return Color(red: 1.0, green: 0.2, blue: 0.15)
        case .forest:   return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .midnight: return Color(red: 1.0, green: 0.45, blue: 0.7)
        case .mono:     return Color.white
        }
    }

    /// Theme tối → chrome sáng để nút/icon không bị chìm vào nền.
    var prefersDarkChrome: Bool {
        self != .system
    }

    /// Màu icon / chữ trên nút điều khiển.
    var controlForeground: Color {
        prefersDarkChrome ? digitColor : Color.primary
    }

    /// Nền nút — đủ sáng trên theme tối.
    var controlFill: Color {
        prefersDarkChrome
            ? Color.white.opacity(0.16)
            : Color.primary.opacity(0.08)
    }

    /// Viền nút.
    var controlStroke: Color {
        prefersDarkChrome
            ? digitColor.opacity(0.45)
            : Color.primary.opacity(0.18)
    }

    /// Icon phụ trên header (ellipsis, close).
    var secondaryChrome: Color {
        prefersDarkChrome ? Color.white.opacity(0.75) : Color.secondary
    }
}
