import SwiftUI

/// Sheet tạo timer mới — nhập phút/giờ hoặc chọn thời điểm trong ngày.
struct NewTimerSheet: View {
    @ObservedObject var app: AppViewModel
    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case duration = "Duration"
        case untilTime = "Until time"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .duration
    @State private var title: String = "Timer"
    @State private var hours: Int = 0
    @State private var minutes: Int = 25
    @State private var seconds: Int = 0
    @State private var untilHour: Int = Calendar.current.component(
        .hour,
        from: Calendar.current.date(byAdding: .minute, value: 25, to: Date()) ?? Date()
    )
    @State private var untilMinute: Int = Calendar.current.component(
        .minute,
        from: Calendar.current.date(byAdding: .minute, value: 25, to: Date()) ?? Date()
    )
    @State private var theme: TimerTheme = .system
    @State private var sound: String = "Glass"
    @State private var autoStart = true
    @State private var selectedPreset: TimerPreset?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Timer")
                .font(.title2.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(app.presets) { preset in
                        Button {
                            applyPreset(preset)
                        } label: {
                            Label(preset.name, systemImage: preset.symbolName)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedPreset?.id == preset.id ? .accentColor : .secondary)
                    }
                }
            }

            // Title + mode — ngoài Form để tránh style đè
            VStack(alignment: .leading, spacing: 10) {
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)

                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // Duration / Until time — cùng card style
            Group {
                if mode == .duration {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        DurationHMSFields(hours: $hours, minutes: $minutes, seconds: $seconds)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Until time")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        UntilTimeFields(hour: $untilHour, minute: $untilMinute)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground)
                }
            }

            Form {
                Picker("Theme", selection: $theme) {
                    ForEach(TimerTheme.allCases) { Text($0.title).tag($0) }
                }

                Picker("Sound", selection: $sound) {
                    ForEach(SoundService.availableSounds, id: \.self) { Text($0).tag($0) }
                }

                Toggle("Start immediately", isOn: $autoStart)
            }
            .formStyle(.grouped)
            .frame(minHeight: 140)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Create") { create() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(computedSeconds < 1)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            theme = app.preferences.defaultTheme
            sound = app.preferences.defaultSound
            let total = Int(app.preferences.defaultDurationSeconds)
            hours = total / 3600
            minutes = (total % 3600) / 60
            seconds = total % 60
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
    }

    private var computedSeconds: TimeInterval {
        switch mode {
        case .duration:
            return TimeInterval(hours * 3600 + minutes * 60 + seconds)
        case .untilTime:
            return TimeFormatter.secondsUntil(hour: untilHour, minute: untilMinute)
        }
    }

    private func applyPreset(_ preset: TimerPreset) {
        selectedPreset = preset
        title = preset.name
        theme = preset.theme
        sound = preset.soundName
        mode = .duration
        let total = Int(preset.seconds)
        hours = total / 3600
        minutes = (total % 3600) / 60
        seconds = total % 60
    }

    private func create() {
        app.createTimer(
            title: title.isEmpty ? "Timer" : title,
            seconds: computedSeconds,
            theme: theme,
            sound: sound,
            autoStart: autoStart
        )
        dismiss()
    }
}
