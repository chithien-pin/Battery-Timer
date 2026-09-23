import SwiftUI

/// Nút Start / Pause / Reset / +1m / +5m / +30m — contrast theo theme.
struct TimerControlsView: View {
    @ObservedObject var viewModel: TimerViewModel

    private var theme: TimerTheme { viewModel.model.theme }

    var body: some View {
        HStack(spacing: 6) {
            controlButton(
                systemName: viewModel.model.status == .running ? "pause.fill" : "play.fill",
                help: viewModel.model.status == .running ? "Pause" : "Start"
            ) {
                viewModel.toggleStartPause()
            }

            controlButton(systemName: "arrow.counterclockwise", help: "Reset") {
                viewModel.reset()
            }

            Spacer(minLength: 2)

            addButton(label: "+1m", seconds: 60)
            addButton(label: "+5m", seconds: 5 * 60)
            addButton(label: "+30m", seconds: 30 * 60)
        }
    }

    private func controlButton(systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.controlForeground)
                .frame(width: 34, height: 28)
                .background(theme.controlFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(theme.controlStroke, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func addButton(label: String, seconds: TimeInterval) -> some View {
        Button {
            viewModel.addTime(seconds: seconds)
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(theme.controlForeground)
                .frame(minWidth: 40, minHeight: 28)
                .padding(.horizontal, 4)
                .background(theme.controlFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(theme.controlStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help("Add \(label.replacingOccurrences(of: "+", with: ""))")
    }
}
