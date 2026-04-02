import Foundation
import SwiftUI

class ScanViewModel: ObservableObject {
    @Published var peers: [TailscalePeer] = []
    @Published var isScanning = false
    @Published var statusMessage = "Press Refresh to scan your Tailscale network"
    @Published var errorMessage: String?

    private var scanTask: Task<Void, Never>?

    @MainActor
    func startScan() {
        scanTask?.cancel()
        scanTask = Task {
            await performScan()
        }
    }

    @MainActor
    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        statusMessage = "Scan cancelled"
    }

    @MainActor
    private func performScan() async {
        isScanning = true
        errorMessage = nil
        peers = []
        statusMessage = "Fetching Tailscale peers..."

        // Step 1: Get peer list
        let status: TailscaleStatusResponse
        do {
            status = try await TailscaleAPIClient.fetchStatus()
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Failed to connect to Tailscale"
            isScanning = false
            return
        }

        // Build peer list from status
        var discoveredPeers: [TailscalePeer] = []

        // Add self
        if let selfStatus = status.selfStatus, let ip = selfStatus.firstIPv4 {
            discoveredPeers.append(TailscalePeer(
                id: "self",
                hostName: selfStatus.hostName,
                dnsName: selfStatus.dnsName.replacingOccurrences(of: ".$", with: "", options: .regularExpression),
                ipAddress: ip,
                os: selfStatus.os ?? "unknown",
                services: [],
                isScanning: true
            ))
        }

        // Add online peers
        if let peerMap = status.peer {
            for (key, peerStatus) in peerMap {
                guard peerStatus.online == true, let ip = peerStatus.firstIPv4 else { continue }
                discoveredPeers.append(TailscalePeer(
                    id: key,
                    hostName: peerStatus.hostName,
                    dnsName: peerStatus.dnsName.replacingOccurrences(of: "\\.$", with: "", options: .regularExpression),
                    ipAddress: ip,
                    os: peerStatus.os ?? "unknown",
                    services: [],
                    isScanning: true
                ))
            }
        }

        discoveredPeers.sort { $0.hostName.lowercased() < $1.hostName.lowercased() }
        peers = discoveredPeers

        let totalPeers = peers.count
        statusMessage = "Scanning \(totalPeers) peers for web services..."

        // Step 2: Scan ports on each peer concurrently
        await withTaskGroup(of: (Int, [WebService]).self) { group in
            for (index, peer) in peers.enumerated() {
                group.addTask { [ip = peer.ipAddress] in
                    let openPorts = await PortScanner.scan(host: ip)
                    var services: [WebService] = []
                    for (port, isHTTPS) in openPorts {
                        let scheme = isHTTPS ? "https" : "http"
                        if let url = URL(string: "\(scheme)://\(ip):\(port)") {
                            services.append(WebService(
                                port: port,
                                isHTTPS: isHTTPS,
                                title: nil,
                                url: url
                            ))
                        }
                    }
                    return (index, services)
                }
            }

            for await (index, services) in group {
                guard !Task.isCancelled else { return }
                if index < peers.count {
                    peers[index].services = services
                    peers[index].isScanning = false
                    let scanned = peers.filter { !$0.isScanning }.count
                    statusMessage = "Scanned \(scanned)/\(totalPeers) peers..."
                }
            }
        }

        guard !Task.isCancelled else { return }

        // Step 3: Fetch titles for discovered services
        let totalServices = peers.reduce(0) { $0 + $1.services.count }
        if totalServices > 0 {
            statusMessage = "Fetching page titles for \(totalServices) services..."
        }

        await withTaskGroup(of: (Int, Int, String?).self) { group in
            for (peerIndex, peer) in peers.enumerated() {
                for (serviceIndex, service) in peer.services.enumerated() {
                    group.addTask {
                        let title = await TitleFetcher.fetchTitle(url: service.url)
                        return (peerIndex, serviceIndex, title)
                    }
                }
            }

            for await (peerIndex, serviceIndex, title) in group {
                guard !Task.isCancelled else { return }
                if peerIndex < peers.count && serviceIndex < peers[peerIndex].services.count {
                    peers[peerIndex].services[serviceIndex].title = title
                }
            }
        }

        guard !Task.isCancelled else { return }

        // Also try HTTPS for ports we initially tried as HTTP (and vice versa) if title fetch failed
        // This helps detect services on non-standard ports that use HTTPS
        await withTaskGroup(of: (Int, Int, String?, URL?).self) { group in
            for (peerIndex, peer) in peers.enumerated() {
                for (serviceIndex, service) in peer.services.enumerated() {
                    if service.title == nil {
                        let altScheme = service.isHTTPS ? "http" : "https"
                        if let altURL = URL(string: "\(altScheme)://\(peer.ipAddress):\(service.port)") {
                            group.addTask {
                                let title = await TitleFetcher.fetchTitle(url: altURL)
                                return (peerIndex, serviceIndex, title, title != nil ? altURL : nil)
                            }
                        }
                    }
                }
            }

            for await (peerIndex, serviceIndex, title, altURL) in group {
                guard !Task.isCancelled else { return }
                if let title = title, let url = altURL,
                   peerIndex < peers.count,
                   serviceIndex < peers[peerIndex].services.count {
                    peers[peerIndex].services[serviceIndex].title = title
                    peers[peerIndex].services[serviceIndex] = WebService(
                        port: peers[peerIndex].services[serviceIndex].port,
                        isHTTPS: url.scheme == "https",
                        title: title,
                        url: url
                    )
                }
            }
        }

        let servicesFound = peers.reduce(0) { $0 + $1.services.count }
        statusMessage = "Found \(servicesFound) web services across \(totalPeers) peers"
        isScanning = false
    }
}
