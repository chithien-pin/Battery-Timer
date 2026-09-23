import SwiftUI

struct SettingsView: View {
    @ObservedObject var app: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var prefs: AppPreferences
    @State private var hours: Int = 0
    @State private var minutes: Int = 25
    @State private var seconds: Int = 0

    init(app: AppViewModel) {
        self.app = app
        _prefs = State(initialValue: app.preferences)
        let total = Int(app.preferences.defaultDurationSeconds)
        _hours = State(initialValue: total / 3600)
        _minutes = State(initialValue: (total % 3600) / 60)
        _seconds = State(initialValue: total % 60)
    }

    private var quickDurationSeconds: TimeInterval {
        TimeInterval(max(0, hours * 3600 + minutes * 60 + seconds))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2.weight(.semibold))

            // Duration ngoài Form — tránh lệch TextField trên macOS
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick duration (h / m / s)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                DurationHMSFields(hours: $hours, minutes: $minutes, seconds: $seconds)
                Text("Default for new timers: \(TimeFormatter.countdown(quickDurationSeconds))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Use as default") {
                        prefs.defaultDurationSeconds = max(1, quickDurationSeconds)
                    }
                    .disabled(quickDurationSeconds < 1)

                    if let focused = app.focusedTimer {
                        Button("Apply to “\(focused.model.title)”") {
                            let secs = max(1, quickDurationSeconds)
                            prefs.defaultDurationSeconds = secs
                            focused.setDuration(seconds: secs)
                        }
                        .disabled(quickDurationSeconds < 1)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
            )

            Form {
                Section("Alerts") {
                    Toggle("Bypass Focus / Do Not Disturb", isOn: $prefs.bypassFocusMode)
                    Toggle("Center window when finished", isOn: $prefs.autoCenterOnFinish)
                    Toggle("Enlarge window when finished", isOn: $prefs.enlargeOnFinish)
                }

                Section("Window") {
                    Toggle("Float above fullscreen apps (screenSaver level)", isOn: $prefs.useScreenSaverLevel)
                }

                Section("Defaults for new timers") {
                    Picker("Theme", selection: $prefs.defaultTheme) {
                        ForEach(TimerTheme.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Sound", selection: $prefs.defaultSound) {
                        ForEach(SoundService.availableSounds, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Display mode", selection: $prefs.defaultDisplayMode) {
                        ForEach(DisplayMode.allCases) { Text($0.title).tag($0) }
                    }
                }

                Section("Keyboard shortcuts") {
                    LabeledContent("Start / Pause", value: "⌘⇧T")
                    LabeledContent("Add +1 minute", value: "⌘⇧=")
                    LabeledContent("New timer", value: "⌘⇧N")
                    Text("Global shortcuts need Accessibility permission in System Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") {
                    prefs.defaultDurationSeconds = max(1, quickDurationSeconds)
                    app.updatePreferences(prefs)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 480, height: 560)
    }
}
