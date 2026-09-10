import SwiftUI

struct TimeOfDayPicker: View {
    let title: String
    @Binding var time: TimeOfDay

    var body: some View {
        DatePicker(
            title,
            selection: dateBinding,
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.compact)
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { time.date(on: .now) },
            set: { time = TimeOfDay(date: $0) }
        )
    }
}
