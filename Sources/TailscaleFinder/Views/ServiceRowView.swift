import SwiftUI
import AppKit

struct ServiceRowView: View {
    let service: WebService
    let hostName: String

    var body: some View {
        Button(action: openInBrowser) {
            HStack(spacing: 12) {
                Image(systemName: service.isHTTPS ? "lock.fill" : "globe")
                    .foregroundColor(service.isHTTPS ? .green : .blue)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(service.displayTitle)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(service.isHTTPS ? "https" : "http")://\(hostName):\(service.port)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(":\(service.port)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)

                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.accentColor)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openInBrowser() {
        // Use the DNS name for the URL if possible, falling back to IP
        NSWorkspace.shared.open(service.url)
    }
}
