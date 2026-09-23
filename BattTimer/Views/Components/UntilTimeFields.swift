import SwiftUI

/// Chọn giờ:phút trong ngày — cùng ngôn ngữ UI với DurationHMSFields.
struct UntilTimeFields: View {
    @Binding var hour: Int
    @Binding var minute: Int

    private let boxHeight: CGFloat = 32
    private let boxWidth: CGFloat = 108

    private var remainingSeconds: TimeInterval {
        TimeFormatter.secondsUntil(hour: hour, minute: minute)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                unit(title: "HOUR", value: $hour, range: 0...23, digits: 2)
                Text(":")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
                unit(title: "MIN", value: $minute, range: 0...59, digits: 2)
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                Text("Ends in \(TimeFormatter.compact(remainingSeconds))")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formattedClock)
                    .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
            }

            HStack(spacing: 8) {
                quickChip("+15m") { addMinutesFromNow(15) }
                quickChip("+30m") { addMinutesFromNow(30) }
                quickChip("+1h") { addMinutesFromNow(60) }
                quickChip("Round") { roundToNextFive() }
            }
        }
    }

    private var formattedClock: String {
        String(format: "%02d:%02d", hour, minute)
    }

    private func unit(title: String, value: Binding<Int>, range: ClosedRange<Int>, digits: Int) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(height: 14)

            HStack(spacing: 0) {
                stepButton(systemName: "minus", enabled: true) {
                    if value.wrappedValue <= range.lowerBound {
                        value.wrappedValue = range.upperBound
                    } else {
                        value.wrappedValue -= 1
                    }
                }

                TextField(
                    "",
                    text: Binding(
                        get: {
                            String(format: "%0\(digits)d", value.wrappedValue)
                        },
                        set: { raw in
                            let digitsOnly = raw.filter(\.isNumber)
                            guard let parsed = Int(digitsOnly.isEmpty ? "0" : digitsOnly) else { return }
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

                stepButton(systemName: "plus", enabled: true) {
                    if value.wrappedValue >= range.upperBound {
                        value.wrappedValue = range.lowerBound
                    } else {
                        value.wrappedValue += 1
                    }
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

    private func quickChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func addMinutesFromNow(_ minutesToAdd: Int) {
        let target = Calendar.current.date(byAdding: .minute, value: minutesToAdd, to: Date()) ?? Date()
        hour = Calendar.current.component(.hour, from: target)
        minute = Calendar.current.component(.minute, from: target)
    }

    private func roundToNextFive() {
        let now = Date()
        var h = Calendar.current.component(.hour, from: now)
        var m = Calendar.current.component(.minute, from: now)
        let rem = m % 5
        if rem == 0 {
            m += 5
        } else {
            m += (5 - rem)
        }
        if m >= 60 {
            m -= 60
            h = (h + 1) % 24
        }
        hour = h
        minute = m
    }
}
