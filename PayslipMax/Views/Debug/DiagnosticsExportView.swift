import SwiftUI

struct DiagnosticsExportView: View {
    @State private var exportedURL: URL?
    @State private var isSharing = false
    @State private var status: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Diagnostics Bundle")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Export anonymized diagnostics for offline support. No PII included.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button(action: export) {
                    Label("Export Bundle", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("diagnostics_export_button")

                if exportedURL != nil {
                    Button(action: { isSharing = true }) {
                        Label("Share", systemImage: "square.and.arrow.up.on.square")
                    }
                    .buttonStyle(.bordered)
                }
            }

            if !status.isEmpty {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("diagnostics_export_status")
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $isSharing) {
            if let url = exportedURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func export() {
        guard let data = DiagnosticsService.shared.exportBundle() else {
            status = "No diagnostics available yet. Perform a parse first."
            return
        }

        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("diagnostics_\(Int(Date().timeIntervalSince1970)).json")
        do {
            try data.write(to: temp, options: .atomic)
            exportedURL = temp
            status = "Exported diagnostics to: \(temp.lastPathComponent)"
        } catch {
            status = "Failed to export: \(error.localizedDescription)"
        }
    }
}

#Preview {
    DiagnosticsExportView()
}


