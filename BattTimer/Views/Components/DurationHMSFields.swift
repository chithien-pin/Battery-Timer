import SwiftUI

/// Ba ô Hours / Minutes / Seconds — layout cố định, không phụ thuộc Form.
struct DurationHMSFields: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    private let boxHeight: CGFloat = 32
    private let boxWidth: CGFloat = 108

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            unit(title: "H", value: $hours, range: 0...23)
            unit(title: "M", value: $minutes, range: 0...59)
            unit(title: "S", value: $seconds, range: 0...59)
        }
    }

    private func unit(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(height: 14)

            HStack(spacing: 0) {
                stepButton(systemName: "minus", enabled: value.wrappedValue > range.lowerBound) {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
                }

                // Dùng Text + Binding String để tránh Form/FormatStyle làm lệch baseline.
                TextField(
                    "",
                    text: Binding(
                        get: { String(value.wrappedValue) },
                        set: { raw in
                            let digits = raw.filter(\.isNumber)
                            guard let parsed = Int(digits.isEmpty ? "0" : digits) else { return }
                            value.wrappedValue = min(max(parsed, range.lowerBound), range.upperBound)
                        }
                    )
                )
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .labelsHidden()
                .frame(width: 40, height: boxHeight)
                .clipped()

                stepButton(systemName: "plus", enabled: value.wrappedValue < range.upperBound) {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
                }
            }
            .frame(width: boxWidth, height: boxHeight)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .frame(width: boxWidth)
    }

    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.35))
                .frame(width: 28, height: boxHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
