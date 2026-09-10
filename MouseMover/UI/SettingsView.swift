import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView {
            Tab("Movement", systemImage: "cursorarrow.motionlines") {
                MovementSettingsView()
            }
            Tab("Schedule", systemImage: "calendar") {
                ScheduleSettingsView()
            }
            Tab("General", systemImage: "gearshape") {
                GeneralSettingsView()
            }
        }
        .scenePadding()
        .frame(minWidth: 520, minHeight: 560)
        .environmentObject(model)
        .onAppear {
            SettingsPresenter.reveal()
        }
    }
}
