import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Label("QuickMD is installed", systemImage: "doc.richtext")
                .font(.title)
                .bold()

            Text("Preview Markdown directly in Finder with Quick Look.")
                .foregroundStyle(.secondary)

            Divider()

            InstructionRow(
                symbol: "1.circle.fill",
                title: "Enable the extension",
                detail: "Open System Settings › General › Login Items & Extensions › Quick Look, then turn on QuickMD Preview."
            )

            InstructionRow(
                symbol: "2.circle.fill",
                title: "Select a Markdown file",
                detail: "Choose any .md or .markdown file in Finder."
            )

            InstructionRow(
                symbol: "3.circle.fill",
                title: "Press Space",
                detail: "Quick Look displays the rendered document."
            )

            HStack {
                Button(
                    "Open Extensions Settings",
                    systemImage: "puzzlepiece.extension",
                    action: openExtensionsSettings
                )
                .buttonStyle(.borderedProminent)

                Spacer()

                Text("Bundle ID: dev.bunn.quickmd")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .frame(minWidth: 560, idealWidth: 620)
    }

    private func openExtensionsSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
