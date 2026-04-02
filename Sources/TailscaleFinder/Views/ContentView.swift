import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ScanViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar area
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tailscale Finder")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)

                    Button("Stop") {
                        viewModel.cancelScan()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        viewModel.startScan()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("r", modifiers: .command)
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Content area
            if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Connection Error")
                        .font(.headline)
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        viewModel.startScan()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .padding(40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.peers.isEmpty && !viewModel.isScanning {
                VStack(spacing: 12) {
                    Image(systemName: "network")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Peers Discovered")
                        .font(.headline)
                    Text("Make sure Tailscale is running and connected, then press Refresh to scan your network.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                    Button {
                        viewModel.startScan()
                    } label: {
                        Label("Scan Network", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .padding(40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    let peersWithServices = viewModel.peers.filter { !$0.services.isEmpty || $0.isScanning }
                    let peersWithoutServices = viewModel.peers.filter { $0.services.isEmpty && !$0.isScanning }

                    if !peersWithServices.isEmpty {
                        Section("Devices with Web Services") {
                            ForEach(peersWithServices) { peer in
                                DeviceGroupView(peer: peer)
                            }
                        }
                    }

                    if !peersWithoutServices.isEmpty {
                        Section("Other Devices (\(peersWithoutServices.count))") {
                            ForEach(peersWithoutServices) { peer in
                                HStack(spacing: 10) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(.green)
                                    Text(peer.displayName)
                                        .font(.body)
                                    Spacer()
                                    Text(peer.ipAddress)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fontDesign(.monospaced)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            viewModel.startScan()
        }
    }
}
