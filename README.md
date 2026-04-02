# Tailscale Finder

A native macOS application that discovers web services running on your Tailscale network.

## Features

- Automatically discovers all online Tailscale peers
- Scans ~100 common web service ports on each peer (all well-known HTTP/HTTPS ports plus common service ports under 10000)
- Fetches and displays page titles for each discovered service
- Click any service to open it in your default browser
- Refresh button to re-scan the network (Cmd+R)
- Groups devices by those with web services vs. those without
- Handles self-signed certificates (common on internal services)
- Shows HTTPS vs HTTP status with lock icons

## Requirements

- macOS 13.0+ (Ventura or later)
- Apple Silicon (M-series) Mac
- [Tailscale](https://tailscale.com) installed and connected
- Xcode 15+ or Swift 5.9+ toolchain (for building)

## Build & Run

```bash
# Build
swift build

# Run
swift run TailscaleFinder

# Build for release
swift build -c release
```

The release binary will be at `.build/release/TailscaleFinder`.

## How It Works

1. **Peer Discovery**: Calls `tailscale status --json` (or the local API at `127.0.0.1:41112`) to get all peers on your tailnet
2. **Port Scanning**: Uses Apple's Network.framework to perform concurrent TCP connection probes with 500ms timeouts
3. **Title Fetching**: Makes HTTP/HTTPS requests to open ports and parses the HTML `<title>` tag
4. **Display**: Shows results in a native SwiftUI interface grouped by device

## Scanned Ports

The scanner checks these port categories:
- **Standard web ports**: 80, 443, 8080, 8443, 3000, 5000, 9090, etc.
- **Development servers**: 3000, 3001, 4200, 5173, 5174, 8000, 8888
- **Infrastructure**: 2375 (Docker), 5601 (Kibana), 6443 (K8s), 8500 (Consul), 9200 (Elasticsearch)
- **Database web UIs**: 5984 (CouchDB), 7474 (Neo4j), 8042 (YARN)
- **And many more** — approximately 100 ports total, all under 10000
