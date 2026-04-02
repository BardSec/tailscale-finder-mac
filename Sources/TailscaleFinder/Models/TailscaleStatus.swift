import Foundation

struct TailscaleStatusResponse: Codable {
    let peer: [String: PeerStatus]?
    let selfStatus: PeerStatus?
    let magicDNSSuffix: String?

    enum CodingKeys: String, CodingKey {
        case peer = "Peer"
        case selfStatus = "Self"
        case magicDNSSuffix = "MagicDNSSuffix"
    }
}

struct PeerStatus: Codable {
    let hostName: String
    let dnsName: String
    let tailscaleIPs: [String]?
    let online: Bool?
    let os: String?

    enum CodingKeys: String, CodingKey {
        case hostName = "HostName"
        case dnsName = "DNSName"
        case tailscaleIPs = "TailscaleIPs"
        case online = "Online"
        case os = "OS"
    }

    var firstIPv4: String? {
        tailscaleIPs?.first { $0.contains(".") && !$0.contains(":") }
    }
}
