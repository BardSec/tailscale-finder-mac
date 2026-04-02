import SwiftUI

struct DeviceGroupView: View {
    let peer: TailscalePeer
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if peer.isScanning {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Scanning ports...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } else if peer.services.isEmpty {
                Text("No web services found")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(peer.services) { service in
                    ServiceRowView(service: service, hostName: peer.dnsName.isEmpty ? peer.ipAddress : peer.dnsName)
                    if service.id != peer.services.last?.id {
                        Divider()
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: osIcon(for: peer.os))
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(peer.displayName)
                            .font(.headline)
                        if !peer.services.isEmpty {
                            Text("\(peer.services.count)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Color.accentColor)
                                .cornerRadius(8)
                        }
                    }

                    Text(peer.ipAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontDesign(.monospaced)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func osIcon(for os: String) -> String {
        switch os.lowercased() {
        case "macos":
            return "desktopcomputer"
        case "linux":
            return "server.rack"
        case "windows":
            return "pc"
        case "ios":
            return "iphone"
        case "android":
            return "phone"
        default:
            return "network"
        }
    }
}
