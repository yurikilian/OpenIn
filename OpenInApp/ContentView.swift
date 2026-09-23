import SwiftUI
import FinderSync

struct ContentView: View {

    var body: some View {

        VStack(spacing: 20) {

            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 48))

            Text("OpenIn")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text(
                """
                Adds an "Open in" menu to Finder.

                Supported applications:
                • Visual Studio Code
                • Zed
                • IntelliJ IDEA
                • Orca
                """
            )
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)

            Divider()

            HStack {
                Text("Finder Extension")

                Spacer()

                if FIFinderSyncController.isExtensionEnabled {
                    Label(
                        "Enabled",
                        systemImage: "checkmark.circle.fill"
                    )
                } else {
                    Label(
                        "Disabled",
                        systemImage: "xmark.circle"
                    )
                }
            }

            Button("Manage Finder Extension") {
                FIFinderSyncController.showExtensionManagementInterface()
            }
            .buttonStyle(.borderedProminent)

        }
        .padding(32)
        .frame(
            minWidth: 440,
            minHeight: 320
        )
    }
}

#Preview {
    ContentView()
}
