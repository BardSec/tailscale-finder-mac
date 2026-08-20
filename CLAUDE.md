# Tailscale Finder

Native macOS app that discovers web services on your Tailscale network. Scans
common ports, displays service titles, handles self-signed certs.

## Stack

- Swift 5.9+ / SwiftUI
- Network.framework for TCP socket operations
- Swift Package Manager
- Requires macOS 13.0+ (Ventura)

## Project Layout

```
Sources/TailscaleFinder/
  TailscaleFinderApp.swift  # SwiftUI App entry point
  Models/                   # Data structures (Peer, Service)
  Services/                 # Peer discovery + port scanning
  ViewModels/               # State management (Observable)
  Views/                    # SwiftUI components
Package.swift               # SPM manifest
Info.plist                  # App metadata
TailscaleFinder.entitlements
```

## Dev Setup

```bash
swift build                 # build (debug)
swift run TailscaleFinder   # run
swift build -c release      # optimized build
```

Or open in Xcode for GUI development.

## How It Works

1. Calls `tailscale status --json` to discover peers on the tailnet
2. Scans ~100 common ports per peer (80, 443, 3000, 5000, 8080, etc.)
3. HTTP/HTTPS requests parse `<title>` tags for service names
4. Groups devices by those with/without web services

## Key Patterns

- SwiftUI Observable pattern for state (ViewModel)
- Concurrent port scanning via Network.framework
- 500ms TCP timeout per port
- Allows self-signed certs (internal network assumption)
- Requires Tailscale installed and connected
