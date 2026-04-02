import Foundation

struct TailscalePeer: Identifiable {
    let id: String
    let hostName: String
    let dnsName: String
    let ipAddress: String
    let os: String
    var services: [WebService]
    var isScanning: Bool = false

    var displayName: String {
        hostName.isEmpty ? dnsName : hostName
    }
}

struct WebService: Identifiable {
    let id = UUID()
    let port: Int
    let isHTTPS: Bool
    var title: String?
    let url: URL

    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        return "\(isHTTPS ? "HTTPS" : "HTTP") on port \(port)"
    }
}
