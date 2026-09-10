import SwiftUI

struct ScheduleSettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section {
                Toggle("Run on a daily schedule", isOn: $model.settings.schedule.isEnabled)
            } footer: {
                Text("When this is off, Mouse Mover jiggles whenever it is enabled. When this is on, it only runs inside today’s window.")
            }

            if model.settings.schedule.isEnabled {
                Section {
                    TimeOfDayPicker(title: "Start", time: $model.settings.schedule.start)
                    TimeOfDayPicker(title: "Stop", time: $model.settings.schedule.stop)
                    LabeledContent("Threshold") {
                        Stepper(value: $model.settings.schedule.thresholdMinutes, in: 0...90, step: 1) {
                            Text("± \(model.settings.schedule.thresholdMinutes) min")
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Text("Window")
                } footer: {
                    Text("Each day, start and stop shift independently by up to the threshold. A 09:00 start with ±15 minutes becomes somewhere between 08:45 and 09:15, and the stop time is rolled the same way.")
                }

                Section {
                    LabeledContent("Days") {
                        WeekdayPicker(selection: $model.settings.schedule.activeWeekdays)
                    }
                }

                Section {
                    if let window = model.todaysWindow {
                        LabeledContent("Today’s start") {
                            HStack {
                                Text(window.start, format: .dateTime.hour().minute())
                                    .monospacedDigit()
                                OffsetLabel(minutes: window.startOffsetMinutes)
                            }
                        }
                        LabeledContent("Today’s stop") {
                            HStack {
                                Text(window.end, format: .dateTime.hour().minute())
                                    .monospacedDigit()
                                OffsetLabel(minutes: window.stopOffsetMinutes)
                            }
                        }
                    }
                    Button("Roll new times for today") {
                        model.rerollTodaysWindow()
                    }
                } header: {
                    Text("Today")
                } footer: {
                    Text("Times are chosen once per day and kept if you quit and reopen the app. Tomorrow gets a fresh roll.")
                }
            }
        }
        .formStyle(.grouped)
    }
}
