import SwiftUI

struct FineSlider: View {
    let title: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let format: String
    var help: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(formatted)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
            if let help {
                Text(help)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var formatted: String {
        String(format: format, value.wrappedValue)
    }
}
