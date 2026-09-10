import SwiftUI

struct OffsetLabel: View {
    let minutes: Int

    var body: some View {
        Text(text)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
    }

    private var text: String {
        if minutes == 0 { return "exact" }
        let sign = minutes > 0 ? "+" : "−"
        return "\(sign)\(abs(minutes)) min"
    }
}
