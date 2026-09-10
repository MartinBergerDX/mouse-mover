import SwiftUI

struct WeekdayPicker: View {
    @Binding var selection: WeekdaySet

    private var calendar: Calendar { .current }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                let isOn = selection.contains(weekday)
                Button {
                    var next = selection
                    next.toggle(weekday)
                    selection = next
                } label: {
                    Text(shortLabel(for: weekday))
                        .font(.caption.weight(.semibold))
                        .frame(width: 28, height: 28)
                        .background(isOn ? Color.accentColor : Color.primary.opacity(0.08), in: Circle())
                        .foregroundStyle(isOn ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
                .help(fullLabel(for: weekday))
            }
        }
    }

    private var orderedWeekdays: [Int] {
        let first = calendar.firstWeekday
        return (0..<7).map { ((first - 1 + $0) % 7) + 1 }
    }

    private func shortLabel(for weekday: Int) -> String {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let index = weekday - 1
        guard symbols.indices.contains(index) else { return "\(weekday)" }
        return symbols[index]
    }

    private func fullLabel(for weekday: Int) -> String {
        let symbols = calendar.standaloneWeekdaySymbols
        let index = weekday - 1
        guard symbols.indices.contains(index) else { return "\(weekday)" }
        return symbols[index]
    }
}
