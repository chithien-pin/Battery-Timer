import SwiftUI

/// Popover tuỳ chọn nhanh trên từng cửa sổ timer.
struct TimerOptionsPopover: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var app: AppViewModel

    var body: some View {
        Form {
            TextField("Title", text: Binding(
                get: { viewModel.model.title },
                set: { viewModel.updateTitle($0) }
            ))

            Picker("Theme", selection: Binding(
                get: { viewModel.model.theme },
                set: { viewModel.updateTheme($0) }
            )) {
                ForEach(TimerTheme.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            }

            Picker("Sound", selection: Binding(
                get: { viewModel.model.soundName },
                set: { viewModel.updateSound($0) }
            )) {
                ForEach(SoundService.availableSounds, id: \.self) { name in
                    Text(name).tag(name)
                }
            }

            Picker("Display", selection: Binding(
                get: { viewModel.model.displayMode },
                set: {
                    viewModel.updateDisplayMode($0)
                    WindowManager.shared.applyDisplayMode($0, for: viewModel.id)
                }
            )) {
                ForEach(DisplayMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            Toggle("Click-through (view only)", isOn: Binding(
                get: { viewModel.model.clickThrough },
                set: {
                    viewModel.updateClickThrough($0)
                    WindowManager.shared.setClickThrough($0, for: viewModel.id)
                }
            ))

            Button("Preview sound") {
                SoundService.shared.play(viewModel.model.soundName)
            }
        }
        .formStyle(.grouped)
        .padding(4)
    }
}
