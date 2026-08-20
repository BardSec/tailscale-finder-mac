# Security Review: Tailscale Finder (macOS)

**Date:** 2026-04-08
**Project Type:** Swift 5.9 / SwiftUI macOS app (Swift Package Manager)

---

## Security Grade: A-

```
0 CRITICAL | 0 HIGH | 3 MEDIUM | 3 LOW | 2 INFO
```

---

## Findings

| # | Severity | Category | File:Line | Issue | Auto-Fix |
|---|----------|----------|-----------|-------|----------|
| 1 | MEDIUM | TLS Verification | Services/TitleFetcher.swift:6-19 | TLS certificate verification disabled globally for all title-fetch requests | No |
| 2 | MEDIUM | Subprocess Execution | Services/TailscaleAPIClient.swift:42 | Hardcoded CLI path executed via Process(); no code signature verification | No |
| 3 | MEDIUM | Unencrypted Local API | Services/TailscaleAPIClient.swift:31 | Tailscale local API called over plain HTTP (http://127.0.0.1:41112) | No |
| 4 | LOW | .gitignore Gaps | .gitignore | Missing coverage for .env, *.pem, *.key, *.p12, credentials files | Yes |
| 5 | LOW | Sensitive Data in UI | Views/ContentView.swift:114, Views/DeviceGroupView.swift:55 | Tailscale IPs displayed in UI (visible in screenshots/screen shares) | No |
| 6 | LOW | Error Message Disclosure | Services/TailscaleAPIClient.swift:12 | Decoding errors include raw localizedDescription which could reveal internal structure | No |
| 7 | INFO | No CI/CD | (project root) | No GitHub Actions or build automation configured | No |
| 8 | INFO | PrivacyInfo | PrivacyInfo.xcprivacy | NSPrivacyAccessedAPITypes is empty; Network.framework usage may need declaration | No |

---

## Key Positives

- **Zero third-party dependencies** — eliminates supply chain risk entirely
- **Properly sandboxed** with only the `network.client` entitlement
- **No secrets** anywhere in source or git history
- **No persistent storage** — all scan data is ephemeral in memory
- **No logging** of sensitive data
- **No user input flows into shell commands** — Process() uses only hardcoded arguments
- **No analytics or telemetry**

---

## Medium Findings Detail

### #1: TLS Certificate Verification Disabled

**File:** `Services/TitleFetcher.swift:6-19`

**Risk:** The `InsecureURLSessionDelegate` accepts ALL server certificates for title-fetch requests. An attacker on the Tailscale network could MITM these connections. Mitigated by the fact that only HTML title text is parsed (no credentials sent), and the Tailscale network is already an encrypted WireGuard tunnel.

**Recommendation:** Acceptable tradeoff for internal network scanner. To harden: try default TLS first, retry with insecure delegate only on certificate errors.

### #2: Hardcoded CLI Path Without Signature Verification

**File:** `Services/TailscaleAPIClient.swift:18, 37-43`

**Risk:** The path `/Applications/Tailscale.app/Contents/MacOS/Tailscale` is executed without verifying its code signature. An attacker with admin access to /Applications could swap in a malicious binary. Mitigated by app sandbox and filesystem permissions.

**Recommendation:** Verify code signature with `SecStaticCode` before execution for defense-in-depth.

### #3: Unencrypted Local API Call

**File:** `Services/TailscaleAPIClient.swift:31`

**Risk:** Call to `http://127.0.0.1:41112/localapi/v1/status` is plain HTTP. Limited to local eavesdropping by other processes. This is Tailscale's own API design (localhost-only).

**Recommendation:** No change needed — this is by Tailscale's design.

---

## Recommended .gitignore Additions

```
.env
*.pem
*.key
*.p12
credentials.json
```
