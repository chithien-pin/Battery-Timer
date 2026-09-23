import SwiftUI

/// Nội dung cửa sổ floating của một timer.
struct TimerWindowView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var app: AppViewModel

    @State private var showPopover = false

    var body: some View {
        GeometryReader { geo in
            let scale = fontScale(for: geo.size)
            let isHUD = viewModel.model.displayMode == .hud
            let isCompact = viewModel.model.displayMode == .compact
            let showControls = !isHUD && (viewModel.model.displayMode == .normal || geo.size.height > 120)

            ZStack {
                backgroundLayer(isHUD: isHUD)

                VStack(spacing: isCompact ? 6 : 10) {
                    if showControls && !isCompact {
                        headerBar
                    }

                    countdownDigits(scale: scale)

                    if showControls {
                        TimerControlsView(viewModel: viewModel)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(isHUD ? 4 : 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: isHUD ? 8 : 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isHUD ? 8 : 14, style: .continuous)
                    .strokeBorder(
                        isHUD
                            ? Color.clear
                            : (viewModel.model.theme.prefersDarkChrome
                                ? viewModel.model.theme.digitColor.opacity(0.25)
                                : Color.primary.opacity(0.12)),
                        lineWidth: 1
                    )
            )
            .shake(trigger: viewModel.shakeTrigger)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                cycleDisplayMode()
            }
            .onTapGesture {
                if viewModel.isAlerting {
                    viewModel.acknowledgeAlert()
                }
                app.focusedTimerID = viewModel.id
            }
            .contextMenu { contextMenu }
        }
        .frame(minWidth: 160, minHeight: 80)
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack(spacing: 8) {
            Text(viewModel.model.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(viewModel.model.theme.digitColor.opacity(0.85))
                .lineLimit(1)

            Spacer()

            statusBadge

            Button {
                showPopover = true
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(viewModel.model.theme.secondaryChrome)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                TimerOptionsPopover(viewModel: viewModel, app: app)
                    .frame(width: 260)
            }

            Button {
                app.removeTimer(id: viewModel.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(viewModel.model.theme.secondaryChrome)
            }
            .buttonStyle(.plain)
            .help("Close timer")
        }
    }

    private var statusBadge: some View {
        Group {
            switch viewModel.model.status {
            case .running:
                Image(systemName: "play.fill")
                    .foregroundStyle(viewModel.model.theme.prefersDarkChrome ? Color(red: 0.45, green: 0.95, blue: 0.55) : .green)
            case .paused:
                Image(systemName: "pause.fill")
                    .foregroundStyle(viewModel.model.theme.prefersDarkChrome ? Color(red: 1.0, green: 0.75, blue: 0.35) : .orange)
            case .finished:
                Image(systemName: "bell.fill")
                    .foregroundStyle(viewModel.model.theme.alertColor)
            case .idle:
                Image(systemName: "circle")
                    .foregroundStyle(viewModel.model.theme.secondaryChrome)
            }
        }
        .font(.system(size: 10))
    }

    private func countdownDigits(scale: CGFloat) -> some View {
        Text(TimeFormatter.countdown(viewModel.displaySeconds))
            .font(.system(size: scale, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(
                viewModel.isAlerting
                    ? viewModel.model.theme.alertColor
                    : viewModel.model.theme.digitColor
            )
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.15), value: viewModel.displaySeconds)
    }

    @ViewBuilder
    private func backgroundLayer(isHUD: Bool) -> some View {
        let base = isHUD
            ? Color.black.opacity(0.35)
            : viewModel.model.theme.backgroundColor.opacity(
                viewModel.model.theme == .system ? 0.92 : 0.94
            )

        if viewModel.isAlerting {
            TimelineView(.animation(minimumInterval: 0.45, paused: false)) { context in
                let on = Int(context.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
                (on ? viewModel.model.theme.alertColor.opacity(0.75) : base)
            }
        } else {
            base
        }
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button(viewModel.model.status == .running ? "Pause" : "Start") {
            viewModel.toggleStartPause()
        }
        Button("Reset") { viewModel.reset() }
        Divider()
        Button("+1 min") { viewModel.addTime(seconds: 60) }
        Button("+5 min") { viewModel.addTime(seconds: 5 * 60) }
        Button("+30 min") { viewModel.addTime(seconds: 30 * 60) }
        Divider()
        Menu("Display") {
            ForEach(DisplayMode.allCases) { mode in
                Button {
                    viewModel.updateDisplayMode(mode)
                    WindowManager.shared.applyDisplayMode(mode, for: viewModel.id)
                } label: {
                    HStack {
                        Text(mode.title)
                        if viewModel.model.displayMode == mode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        Toggle(
            "Click-through",
            isOn: Binding(
                get: { viewModel.model.clickThrough },
                set: {
                    viewModel.updateClickThrough($0)
                    WindowManager.shared.setClickThrough($0, for: viewModel.id)
                }
            )
        )
        Divider()
        Button("Remove Timer", role: .destructive) {
            app.removeTimer(id: viewModel.id)
        }
    }

    // MARK: - Helpers

    private func fontScale(for size: CGSize) -> CGFloat {
        // Scale font theo cạnh ngắn hơn — giữ tỷ lệ đẹp khi resize
        let base = min(size.width / 4.2, size.height / (viewModel.model.displayMode == .hud ? 1.4 : 2.4))
        return max(28, min(base, 160))
    }

    private func cycleDisplayMode() {
        let all = DisplayMode.allCases
        guard let idx = all.firstIndex(of: viewModel.model.displayMode) else { return }
        let next = all[(idx + 1) % all.count]
        viewModel.updateDisplayMode(next)
        WindowManager.shared.applyDisplayMode(next, for: viewModel.id)
    }
}
