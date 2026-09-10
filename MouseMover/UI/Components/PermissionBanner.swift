import SwiftUI

struct PermissionBanner: View {
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Label("Accessibility access is required", systemImage: "hand.raised.fill")
                    .font(.headline)
                Text("macOS ties this permission to this exact app copy. An older Mouse Mover can stay ticked in System Settings while this Xcode build is still blocked.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(AccessibilityPermission.runningAppURL.path)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
                Text("Remove every Mouse Mover entry, run this build, then add this copy and turn it on.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Open System Settings") {
                        AccessibilityPermission.openSystemSettings()
                    }
                    Button("Prompt now") {
                        AccessibilityPermission.request()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        }
    }
}
