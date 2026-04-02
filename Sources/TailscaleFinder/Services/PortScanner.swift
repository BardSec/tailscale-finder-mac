import Foundation
import Network

struct PortScanner {
    // MARK: - Web Servers & Reverse Proxies
    static let webServerPorts: [Int] = [
        80, 81, 88, 280, 443, 591, 593, 832, 981,
        3000, 3001, 4200, 4443, 5000, 5001, 5173, 5174,
        8000, 8001, 8008, 8080, 8081, 8082, 8088, 8181,
        8280, 8443, 8880, 8888, 9000, 9090, 9443
    ]

    // MARK: - Security & Vulnerability Scanners
    static let securityPorts: [Int] = [
        1241,  // Nessus (legacy)
        3790,  // Metasploit/Rapid7
        5986,  // WinRM HTTPS
        8834,  // Nessus / Tenable
        8835,  // Nessus scanner
        9390,  // OpenVAS Manager
        9391,  // OpenVAS Scanner
        9392,  // Greenbone Security Assistant
        4444,  // Metasploit listener
        5985,  // WinRM HTTP
        8089,  // Splunk management
        8191,  // Splunk KV Store
        9997,  // Splunk forwarder
    ]

    // MARK: - SIEM, Logging & Monitoring
    static let observabilityPorts: [Int] = [
        514,   // Syslog
        1514,  // Wazuh agent
        1515,  // Wazuh registration
        3100,  // Grafana Loki
        3200,  // Grafana Tempo
        5044,  // Logstash Beats
        5140,  // Syslog TLS
        5601,  // Kibana
        8086,  // InfluxDB
        8125,  // StatsD
        9090,  // Prometheus
        9093,  // Alertmanager
        9100,  // Prometheus Node Exporter
        9115,  // Blackbox Exporter
        9200,  // Elasticsearch HTTP
        9300,  // Elasticsearch transport
        9411,  // Zipkin
        9440,  // Wazuh dashboard HTTPS
    ]

    // MARK: - Infrastructure & Orchestration
    static let infraPorts: [Int] = [
        902,   // VMware ESXi
        943,   // OpenVPN Access Server
        1194,  // OpenVPN
        2375,  // Docker HTTP
        2376,  // Docker HTTPS
        2377,  // Docker Swarm
        4243,  // Docker (alt)
        4646,  // Nomad
        5000,  // Docker Registry
        6443,  // Kubernetes API
        8443,  // Kubernetes Dashboard
        8500,  // Consul
        8501,  // Consul HTTPS
        8600,  // Consul DNS
        8200,  // Vault
        8201,  // Vault cluster
        9631,  // Habitat Supervisor
        9943,  // Kubernetes alt
        2049,  // NFS
        3260,  // iSCSI
        8006,  // Proxmox VE
        8007,  // Proxmox Backup
        9090,  // Cockpit (Linux web admin)
    ]

    // MARK: - CI/CD & DevOps
    static let cicdPorts: [Int] = [
        8080,  // Jenkins
        8929,  // GitLab Runner
        3000,  // Gitea / Drone CI
        4000,  // GitLab Registry
        5050,  // GitLab Container Registry
        8153,  // GoCD
        8111,  // TeamCity
        8065,  // Mattermost
        9000,  // SonarQube
    ]

    // MARK: - Database Web UIs & Admin Panels
    static let databasePorts: [Int] = [
        1433,  // MSSQL
        2480,  // OrientDB
        3306,  // MySQL/MariaDB
        5432,  // PostgreSQL
        5433,  // PostgreSQL alt
        5984,  // CouchDB
        6379,  // Redis
        6380,  // Redis TLS
        7474,  // Neo4j Browser
        7687,  // Neo4j Bolt
        8042,  // YARN ResourceManager
        8529,  // ArangoDB
        8983,  // Apache Solr
        9042,  // Cassandra CQL
        9160,  // Cassandra Thrift
        15672, // RabbitMQ Management (exception: over 10000 but very common)
        27017, // MongoDB (exception: very common for devs)
    ]

    // MARK: - Network & Firewall Admin
    static let networkAdminPorts: [Int] = [
        161,   // SNMP
        162,   // SNMP Trap
        199,   // SNMP multiplexer
        389,   // LDAP
        443,   // HTTPS (firewalls/routers)
        636,   // LDAPS
        1080,  // SOCKS proxy
        1433,  // MSSQL
        1812,  // RADIUS Auth
        1813,  // RADIUS Accounting
        2083,  // cPanel SSL
        2087,  // WHM SSL
        2096,  // cPanel Webmail SSL
        3128,  // Squid Proxy
        3389,  // RDP
        4100,  // Ubiquiti UniFi (alt)
        5900,  // VNC
        8291,  // MikroTik Winbox
        8443,  // UniFi Controller
        8728,  // MikroTik API
        8729,  // MikroTik API SSL
    ]

    // MARK: - Home Lab & Self-Hosted
    static let homelabPorts: [Int] = [
        53,    // DNS (Pi-hole, AdGuard)
        81,    // Nginx Proxy Manager
        443,   // Reverse proxy HTTPS
        1080,  // SOCKS
        1883,  // MQTT
        1900,  // UPnP/SSDP
        2283,  // Immich
        3000,  // Grafana / Homepage
        3579,  // Tautulli
        4443,  // Portainer HTTPS
        5000,  // Synology DSM HTTP
        5001,  // Synology DSM HTTPS
        5055,  // Overseerr/Jellyseerr
        5800,  // noVNC
        6767,  // Bazarr
        7575,  // Homarr
        7878,  // Radarr
        8096,  // Jellyfin
        8123,  // Home Assistant
        8188,  // ComfyUI
        8384,  // Syncthing
        8443,  // Unifi
        8581,  // Homebridge
        8686,  // Lidarr
        8787,  // Readarr
        8920,  // Jellyfin HTTPS
        8989,  // Sonarr
        9091,  // Transmission
        9117,  // Jackett
        9696,  // Prowlarr
        9980,  // Collabora Online
        9981,  // TVHeadend
    ]

    // MARK: - Development Frameworks
    static let devPorts: [Int] = [
        1010,  // Custom dev
        1234,  // Parcel bundler
        1311,  // Dell iDRAC (also dev)
        3333,  // Vite (alt) / misc dev
        4000,  // Phoenix / Hugo
        4001,  // IPFS API
        4321,  // Astro
        4567,  // Sinatra
        4848,  // GlassFish
        5173,  // Vite
        5174,  // Vite (alt)
        5500,  // Live Server (VS Code)
        5555,  // Android ADB / dev
        6000,  // X11
        6006,  // TensorBoard
        6080,  // noVNC
        7000,  // Aqueduct / generic dev
        7001,  // WebLogic
        7002,  // WebLogic SSL
        7070,  // Generic dev
        7080,  // Generic dev
        8000,  // Django / generic dev
        8001,  // Generic dev
        8009,  // Apache AJP
        8020,  // HDFS NameNode
        8333,  // Bitcoin Core RPC
        8761,  // Spring Eureka
        8888,  // Jupyter Notebook
        9001,  // Portainer agent
        9002,  // PHP-FPM status
        9999,  // Generic dev/test
    ]

    /// All unique ports to scan, combined from all categories
    static let allPorts: [Int] = {
        Array(Set(
            webServerPorts + securityPorts + observabilityPorts +
            infraPorts + cicdPorts + databasePorts +
            networkAdminPorts + homelabPorts + devPorts
        )).sorted()
    }()

    /// Ports that are typically HTTPS
    static let httpsPortSet: Set<Int> = [
        443, 2083, 2087, 2096, 4443, 5001, 5986, 6380, 6443,
        7443, 8007, 8201, 8443, 8501, 8729, 8920, 9443, 9440
    ]

    /// Scan all target ports on a given host
    static func scan(host: String, timeout: TimeInterval = 0.5, maxConcurrent: Int = 80) async -> [(port: Int, isHTTPS: Bool)] {
        let allPorts = Self.allPorts

        let results = await withTaskGroup(of: (Int, Bool)?.self, returning: [(port: Int, isHTTPS: Bool)].self) { group in
            var collected: [(port: Int, isHTTPS: Bool)] = []
            var index = 0

            // Seed initial batch
            while index < allPorts.count && index < maxConcurrent {
                let port = allPorts[index]
                group.addTask {
                    let open = await probePort(host: host, port: port, timeout: timeout)
                    if open {
                        return (port, httpsPortSet.contains(port))
                    }
                    return nil
                }
                index += 1
            }

            for await result in group {
                if let r = result {
                    collected.append(r)
                }
                // Launch next port
                if index < allPorts.count {
                    let port = allPorts[index]
                    group.addTask {
                        let open = await probePort(host: host, port: port, timeout: timeout)
                        if open {
                            return (port, httpsPortSet.contains(port))
                        }
                        return nil
                    }
                    index += 1
                }
            }

            return collected
        }

        return results.sorted { $0.port < $1.port }
    }

    /// Probe a single TCP port using Network.framework
    private static func probePort(host: String, port: Int, timeout: TimeInterval) async -> Bool {
        await withCheckedContinuation { continuation in
            let nwHost = NWEndpoint.Host(host)
            let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))
            let connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)

            let resumed = LockedBool()

            @Sendable func safeResume(_ value: Bool) {
                guard resumed.testAndSet() else { return }
                connection.cancel()
                continuation.resume(returning: value)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    safeResume(true)
                case .failed, .cancelled:
                    safeResume(false)
                case .waiting:
                    safeResume(false)
                default:
                    break
                }
            }

            connection.start(queue: .global(qos: .utility))

            // Timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                safeResume(false)
            }
        }
    }
}

/// Thread-safe boolean using os_unfair_lock for async-safe access
private final class LockedBool: @unchecked Sendable {
    private var value = false
    private let _lock = NSLock()

    /// Returns true if this is the first call (was false, now set to true)
    func testAndSet() -> Bool {
        _lock.lock()
        defer { _lock.unlock() }
        if value { return false }
        value = true
        return true
    }
}
