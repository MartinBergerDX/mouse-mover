import SwiftUI

struct MovementSettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section {
                Picker("Pattern", selection: $model.settings.movement.pattern) {
                    ForEach(MovementPattern.allCases) { pattern in
                        Label(pattern.title, systemImage: pattern.systemImage)
                            .tag(pattern)
                    }
                }
                Text(model.settings.movement.pattern.detail)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Path")
            }

            Section {
                FineSlider(
                    title: "Interval",
                    value: $model.settings.movement.intervalSeconds,
                    range: 0.5...60,
                    step: 0.5,
                    format: "%.1f s",
                    help: "Stillness required before the next jiggle. Mouse or keyboard input restarts this countdown."
                )
                FineSlider(
                    title: "Interval jitter",
                    value: $model.settings.movement.intervalJitterPercent,
                    range: 0...80,
                    step: 1,
                    format: "%.0f%%",
                    help: "Randomizes the wait so the cadence is not identical every cycle."
                )
            } header: {
                Text("Timing")
            }

            Section {
                FineSlider(
                    title: "Distance",
                    value: $model.settings.movement.distancePixels,
                    range: 1...80,
                    step: 1,
                    format: "%.0f px",
                    help: "Peak travel of the pointer during a jiggle."
                )
                FineSlider(
                    title: "Distance jitter",
                    value: $model.settings.movement.distanceJitterPercent,
                    range: 0...80,
                    step: 1,
                    format: "%.0f%%"
                )
                FineSlider(
                    title: "Duration",
                    value: $model.settings.movement.durationMilliseconds,
                    range: 40...1_200,
                    step: 10,
                    format: "%.0f ms",
                    help: "How long a single jiggle takes to complete."
                )
                FineSlider(
                    title: "Smoothness",
                    value: Binding(
                        get: { model.settings.movement.smoothness * 100 },
                        set: { model.settings.movement.smoothness = $0 / 100 }
                    ),
                    range: 0...100,
                    step: 5,
                    format: "%.0f%%",
                    help: "Higher values interpolate more points along the path."
                )
            } header: {
                Text("Motion")
            } footer: {
                Text("Smoothness \(Int((model.settings.movement.smoothness * 100).rounded()))% · \(model.settings.movement.stepCount(reduceMotion: false)) steps")
            }

            Section {
                Toggle("Return to the original position", isOn: $model.settings.movement.restorePosition)
                Toggle("Pause while I am using the Mac", isOn: $model.settings.movement.pauseWhileUsingPointer)
                if model.settings.movement.pauseWhileUsingPointer {
                    FineSlider(
                        title: "Idle grace",
                        value: $model.settings.movement.idleGraceSeconds,
                        range: 0.5...10,
                        step: 0.5,
                        format: "%.1f s",
                        help: "After you stop typing or moving the pointer, wait this long before the next jiggle. Any input restarts this countdown."
                    )
                }
            } header: {
                Text("Behavior")
            }

            Section {
                Button("Preview one jiggle") {
                    model.previewMovement()
                }
                .disabled(!model.isAccessibilityTrusted)
            }
        }
        .formStyle(.grouped)
    }
}
