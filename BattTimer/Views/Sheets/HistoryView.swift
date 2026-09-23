import SwiftUI

struct HistoryView: View {
    @ObservedObject var app: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("Clear") {
                    app.clearHistory()
                }
                .disabled(app.history.isEmpty)
            }

            if app.history.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No history yet")
                        .font(.headline)
                    Text("Finished timers will show up here.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(app.history) { entry in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(entry.theme.digitColor)
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .font(.headline)
                            Text("\(entry.finishedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(TimeFormatter.compact(entry.plannedSeconds))
                                .font(.subheadline.monospacedDigit())
                            Text(entry.completed ? "Completed" : "Cancelled")
                                .font(.caption2)
                                .foregroundStyle(entry.completed ? .green : .orange)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.inset)
            }

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440, height: 480)
    }
}
