import Foundation
import Network

struct PortScanner {
    /// Well-known web service ports - always scanned
    static let commonWebPorts: [Int] = [
        80, 443, 3000, 3001, 4200, 4443, 5000, 5001, 5173, 5174,
        8000, 8001, 8008, 8080, 8081, 8082, 8443, 8888, 8880,
        9000, 9090, 9443
    ]

    /// Additional ports commonly used by web services
    static let extendedPorts: [Int] = [
        81, 88, 280, 591, 593, 832, 902, 981, 1010, 1080, 1311,
        2082, 2083, 2086, 2087, 2095, 2096, 2375, 2376, 2480,
        3128, 3306, 3389, 4000, 4001, 4567, 4848, 5050, 5104,
        5432, 5500, 5555, 5601, 5800, 5900, 5984, 5985, 6000,
        6080, 6379, 6443, 7000, 7001, 7002, 7080, 7443, 7474,
        7687, 8009, 8020, 8042, 8088, 8181, 8200, 8280, 8333,
        8500, 8761, 8834, 8888, 8983, 9001, 9002, 9042, 9091,
        9100, 9200, 9300, 9443, 9800, 9943, 9980, 9981, 9990, 9999
    ]

    /// Ports that are typically HTTPS
    static let httpsPortSet: Set<Int> = [443, 2083, 2087, 2096, 4443, 6443, 7443, 8443, 9443]

    /// Scan all target ports on a given host
    static func scan(host: String, timeout: TimeInterval = 0.5, maxConcurrent: Int = 80) async -> [(port: Int, isHTTPS: Bool)] {
        let allPorts = Array(Set(commonWebPorts + extendedPorts)).sorted()

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
