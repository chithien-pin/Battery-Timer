import SwiftUI

/// Cửa sổ điều khiển nhẹ — danh sách timer + mở sheet New/Settings/History.
/// App chủ yếu sống trên menu bar + floating panels; cửa sổ này hiện khi cần.
struct ControlWindowView: View {
    @ObservedObject var app: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if app.timers.isEmpty {
                emptyState
            } else {
                timerList
            }
            Divider()
            footer
        }
        .frame(minWidth: 320, idealWidth: 360, minHeight: 280, idealHeight: 400)
        .sheet(isPresented: $app.showNewTimerSheet) {
            NewTimerSheet(app: app)
        }
        .sheet(isPresented: $app.showSettings) {
            SettingsView(app: app)
        }
        .sheet(isPresented: $app.showHistory) {
            HistoryView(app: app)
        }
    }

    private var header: some View {
        HStack {
            Label("BattTimer", systemImage: "timer")
                .font(.headline)
            Spacer()
            Button {
                app.showNewTimerSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            .help("New timer")
        }
        .padding(12)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No timers yet")
                .font(.title3)
            Text("Create a countdown or pick a preset from the menu bar.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("New Timer") {
                app.showNewTimerSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var timerList: some View {
        List(selection: $app.focusedTimerID) {
            ForEach(app.timers) { vm in
                TimerRowView(viewModel: vm)
                    .tag(vm.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        app.focusTimer(id: vm.id)
                    }
                    .contextMenu {
                        Button("Show Window") { app.openWindow(for: vm) }
                        Button(vm.model.status == .running ? "Pause" : "Start") {
                            vm.toggleStartPause()
                        }
                        Button("Reset") { vm.reset() }
                        Divider()
                        Button("Remove", role: .destructive) {
                            app.removeTimer(id: vm.id)
                        }
                    }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    app.removeTimer(id: app.timers[index].id)
                }
            }
        }
        .listStyle(.inset)
    }

    private var footer: some View {
        HStack {
            Button {
                app.showHistory = true
            } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                app.showSettings = true
            } label: {
                Label("Settings", systemImage: "gear")
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .font(.callout)
    }
}

struct TimerRowView: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(viewModel.model.theme.digitColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.model.title)
                    .font(.body.weight(.medium))
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(TimeFormatter.countdown(viewModel.displaySeconds))
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(viewModel.isAlerting ? viewModel.model.theme.alertColor : .primary)

            Button {
                viewModel.toggleStartPause()
            } label: {
                Image(systemName: viewModel.model.status == .running ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }

    private var statusText: String {
        switch viewModel.model.status {
        case .idle: return "Ready"
        case .running: return "Running"
        case .paused: return "Paused"
        case .finished: return "Finished"
        }
    }
}
